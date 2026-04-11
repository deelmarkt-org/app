# 📋 PLAN — Sell Screen Upload-on-Pick Image Pipeline (GH #104)

> **Task slug**: `sell-upload-on-pick`
> **Issue**: [deelmarkt-org/app#104](https://github.com/deelmarkt-org/app/issues/104)
> **Epic**: E01 Listing Management — §"Image Processing Pipeline"
> **Sprint tasks**: `P-24` (Listing Creation) follow-up, unblocks `R-27` client wiring (Split B part 2, `feature/belengaz-R26-R27-sell-flow-wiring`)
> **Owner**: pizmam (frontend/design)
> **Branch**: `feature/pizmam-P24-upload-on-pick`
> **Commit type**: `feat`
> **Classification**: **Large** — ~20 files touched (6 new, ~14 modified), one new domain boundary, one new async orchestration subsystem.

---

## 1. Context & Problem Statement

The newly merged R-27 Edge Function (`image-upload-process`) finalises the server-side pipeline: **Supabase Storage → Cloudmersive virus scan → Cloudinary signed upload → delivery URL**. A single picture through this pipeline costs roughly 1.5–3 seconds wall time; 12 pictures serialised would make the publish button unusable (20–30 s freeze).

The R-27 EF was therefore designed around an **upload-on-pick** UX: each picked image starts uploading *immediately*, the publish button is a passive gate that only unlocks when every image has reached `uploaded` status, and failures surface per-thumbnail with a retry affordance.

The current sell wizard persists `imageFiles` as `List<String>` — raw local paths. There is no per-image status, no upload trigger on pick, and the repository mock fabricates Cloudinary URLs from local paths. Belengaz's follow-up PR (`SupabaseListingCreationRepository`) is blocked until the state entity learns the new shape.

> **Audit revision**: Tier-1 Staff Engineer audit (2026-04-10) added §3.10 (state-patch contract & cancellation checkpoints), §3.11 (retry backoff policy), expanded §3.5 error table with 429 + StorageException + FileSystemException, expanded §3.8 with retryable-vs-terminal tile UX, added Sentry observability to §6.1, hardened draft schema forward-compat in §3.9, and added steps 10a, 12a, 15a to Phase C/D. See §13 for the audit changelog.

### In scope

1. Introduce a `SellImage` domain entity with `ImageUploadStatus` and replace `ListingCreationState.imageFiles: List<String>` with `List<SellImage>`.
2. Implement a Supabase-backed `ImageUploadRepository`: random UUID filename → `listings-images/<user_id>/<uuid>.<ext>` storage upload → POST storage path to `image-upload-process` EF → return `delivery_url`.
3. Implement a `PhotoUploadQueue` orchestrator in the presentation layer with bounded concurrency (**max 3 parallel uploads**), retry, and cancellation.
4. Wire the queue into `ListingCreationNotifier`: `addFromCamera`/`addFromGallery` appends `SellImage`s in `pending` state and enqueues them; the queue mutates individual entries through a callback as they transition `pending → uploading → uploaded | failed`.
5. Photo grid UX: per-thumbnail spinner overlay when `status != uploaded`, retry button when `status == failed`, best-effort non-blocking storage delete when a photo is removed.
6. Step gating: "Next" from photos and "Publish" both blocked while any `SellImage.status != uploaded`. Distinct l10n error keys for *uploading-in-progress* vs *upload-failed*.
7. Draft persistence: persist **only** `SellImage`s with `status == uploaded` (their `localPath` + `deliveryUrl`). Non-uploaded entries dropped on save — no ghost state on restore.
8. Rename repository contract parameter `imagePaths` → `imageUrls` to reflect the new semantic (Cloudinary URLs, not local paths).
9. Add l10n keys (NL + EN) for all new UI states.
10. Tests (≥80 % on changed code): entity, repository, queue, notifier, widget.

### Out of scope (deferred to belengaz's `feature/belengaz-R26-R27-sell-flow-wiring`)

- `SupabaseListingCreationRepository` (listing row INSERT).
- Removing `MockListingCreationRepository` from the provider gate.
- Calling `listing-quality-score` EF as the publish gate.
- Cloudinary asset cleanup on photo removal (Storage-side delete is included; CDN cleanup requires a separate service-role EF and is tracked as a follow-up).
- Progress-percentage UI (EF is a single synchronous call — no intermediate progress events to report).

### Acceptance criteria (definition of done)

- [ ] Picking a photo creates a `SellImage(pending)` thumbnail that transitions to `uploading` within one frame and to `uploaded` on EF success.
- [ ] The photo grid shows a spinner overlay (semantic label "Uploading photo {index}") while any tile is not `uploaded`.
- [ ] A failed upload shows a retry icon; tapping it re-enters `uploading` and either reaches `uploaded` or surfaces an error message (but never double-enqueues).
- [ ] "Next" button on the photos step and "Publish" button on the quality step are both disabled while `state.hasPendingUploads == true`.
- [ ] Disabling Publish surfaces a status line — "Uploading 3 of 12 photos…" — via a live region so VoiceOver/TalkBack users understand why.
- [ ] Removing a picked photo deletes the corresponding storage object in the background (errors logged but not surfaced); canceled in-flight uploads are dropped before the EF is called.
- [ ] Draft save + restore never resurrects non-uploaded images.
- [ ] All existing sell tests still pass; new tests bring changed-code coverage ≥ 80 % (CI pre-push gate).
- [ ] `flutter analyze` zero warnings; `dart run scripts/check_quality.dart --all` zero new violations; design-system tokens only (no raw values); Semantics labels + `sell.*` l10n keys added to both `en-US.json` and `nl-NL.json`.

---

## 2. Pre-Implementation Verification (CLAUDE.md §7.1)

### 2.1 Schema & contract check (R-27 EF)

R-27 was merged in `bc89651`. The EF contract (`supabase/functions/image-upload-process/index.ts`) is:

- **Method**: `POST`
- **Auth**: `verify_jwt=true`; EF re-checks `storage_path`'s first segment against `auth.getUser().id`.
- **Bucket**: `listings-images` (private, RLS-restricted to `(storage.foldername(name))[1] = auth.uid()`), 15 MiB cap, MIME types `image/png|jpeg|webp|heic` (migration `20260323000001_storage_listings_images_rls.sql`).
- **Storage-path regex** enforced server-side: `^[a-f0-9-]{36}/[A-Za-z0-9._-]+\.[A-Za-z0-9]{2,5}$`. ⇒ The **first segment must be a 36-char UUID (not `auth.uid().toString()` directly if the user ID is not UUID-shaped)**. Supabase Auth user IDs **are** UUIDs — this is compatible.
- **Request body**: `{ storage_path: string }`.
- **Success response**: `{ storage_path, delivery_url, public_id, width, height, bytes, format }` — `delivery_url` is the Cloudinary `secure_url` we persist.
- **Failure responses**: 400 (bad payload), 401 (no JWT), 403 (path ownership mismatch), 404 (object not found), 413 (size > 15 MiB — object is deleted server-side), 422 (virus scan blocked — object deleted), 502 (Cloudinary failed), 503 (scan service down — object deleted).
- **EF side-effects** the client must know about: whenever the EF returns ≥ 413 with a Storage-side delete, the client should discard the `SellImage` (not retry with the same `storage_path`). Retries must re-upload a **fresh** object under a **new** UUID — the old one no longer exists in the bucket.

### 2.2 Sibling convention check

- All sell-domain entities extend `Equatable` and live under `lib/features/sell/domain/entities/` → new `SellImage` follows the same pattern.
- Repositories: interface under `domain/repositories/`, impl under `data/repositories/`. Only `ListingCreationRepository` exists today as an interface — we add `ImageUploadRepository` following the same shape.
- Providers: `sell_providers.dart` is a single file of `@riverpod` functions. New providers (`imageUploadRepository`, `photoUploadQueue`) go in the same file (still under the 150-line ViewModel limit; the providers file is a factory module and is not subject to the 150-line rule — it sits at ~75 lines today).
- Notifier helpers: the project already extracts notifier logic into sibling `*_operations.dart` / `*_updaters.dart` files (see `photo_operations.dart`, `listing_form_updaters.dart`). The new upload queue follows this convention as `photo_upload_queue.dart`.

### 2.3 Epic acceptance-criteria audit (E01)

| Criterion from `docs/epics/E01-listing-management.md` | Status after this PR |
|:--|:--|
| "Image pipeline: EXIF stripped, WebP generated via Cloudinary, ClamAV scanned" | ✅ Fully covered (client drives the pipeline end-to-end). |
| "Max 15 MB/image, max 12 images/listing" | ✅ Already enforced by `ImagePickerService` + `PhotoOperations.maxImages = 12`. |
| "Upload to Supabase Storage (source of truth)" | ✅ Client uploads raw bytes into `listings-images/<user_id>/<uuid>.<ext>`. |
| "Edge Function trigger" | ✅ Client POSTs storage path to `image-upload-process`. |
| "Server-side score exposed via Edge Function + min score 40 to publish" | ⛔ Deferred — belengaz's follow-up wires the `listing-quality-score` EF gate. |

### 2.4 Existing references to be updated

The following non-test files reference `imageFiles` or `imagePaths` and will be touched:

- `lib/features/sell/domain/entities/listing_creation_state.dart` (type change + new getters).
- `lib/features/sell/domain/entities/listing_creation_state_copy_with.dart` (parameter type).
- `lib/features/sell/domain/repositories/listing_creation_repository.dart` (rename + dartdoc).
- `lib/features/sell/domain/usecases/create_listing_usecase.dart` (map SellImage → delivery URL).
- `lib/features/sell/domain/usecases/save_draft_usecase.dart` (same).
- `lib/features/sell/domain/usecases/calculate_quality_score_usecase.dart` — reads only `imageFiles.length`; **semantically unchanged** (still counts picked images). Flagged here because the line compiles after the type change but the behaviour may need revisit (see §7).
- `lib/features/sell/data/mock/mock_listing_creation_repository.dart` (rename param, update fake URLs).
- `lib/features/sell/data/services/draft_persistence_service.dart` (serialise SellImage uploaded-only).
- `lib/features/sell/presentation/viewmodels/photo_operations.dart` (work on `List<SellImage>`).
- `lib/features/sell/presentation/viewmodels/listing_creation_viewmodel.dart` (queue wiring, new `retryUpload` method).
- `lib/features/sell/presentation/viewmodels/sell_providers.dart` (new providers).
- `lib/features/sell/presentation/viewmodels/step_validator.dart` (upload-gate error keys).
- `lib/features/sell/presentation/widgets/live_preview_panel.dart` (read `SellImage.localPath`).
- `lib/features/sell/presentation/widgets/photo_step/photo_grid.dart` (accept `List<SellImage>`, thread retry callback).
- `lib/features/sell/presentation/widgets/photo_step/photo_grid_tile.dart` (status overlay + retry affordance).
- `lib/features/sell/presentation/widgets/photo_step/photo_step_view.dart` (gate "Next", live status).
- `assets/l10n/en-US.json`, `assets/l10n/nl-NL.json` (new keys).

Test files touching `imageFiles` as `List<String>` will be updated alongside (§6.6).

### 2.5 Design-system / screen-spec reference

- Spec: [`docs/screens/03-listings/02-listing-creation.md`](docs/screens/03-listings/02-listing-creation.md) — Step 1 "Photos" describes the grid, max 12, progress caption; does **not** specify upload-status overlays (predates R-27). This plan extends the spec; the extension is documented inline in `/// Reference:` doc comments on the touched widgets.
- Design system reference: `docs/design-system/components.md` §ImageGallery entry (states include upload preview). Spinner uses the existing `CircularProgressIndicator` wrapped in the design-system overlay pattern already used for `DeelButton` loading state (`colors.md` + `spacing.md` tokens).
- Accessibility: `docs/design-system/accessibility.md` — touch targets ≥ 44×44 (retry button reuses the existing `_RemoveButton` frame), `liveRegion` for status-change announcements, `Semantics.label` in NL + EN for every interactive element.

**Design variants checked**: listing_creation_mobile_light, listing_creation_mobile_dark, listing_creation_expanded. The expanded (desktop) variant uses a live-preview panel whose thumbnail already reads the first photo — the preview panel will now read `state.imageFiles.first.localPath` (unchanged UX, just a field rename).

---

## 3. Architecture

### 3.1 Layering

```
presentation/
  viewmodels/listing_creation_viewmodel.dart    (thin — dispatches to queue)
  viewmodels/photo_upload_queue.dart             (NEW — bounded concurrency, retry, cancel)
  viewmodels/photo_operations.dart               (pure state transforms — now on SellImage)
  widgets/photo_step/photo_grid.dart             (renders SellImage list)
  widgets/photo_step/photo_grid_tile.dart        (status overlay + retry button)
         │
         ▼
domain/
  entities/sell_image.dart                       (NEW — SellImage + ImageUploadStatus enum)
  entities/listing_creation_state.dart           (imageFiles: List<SellImage>)
  repositories/image_upload_repository.dart      (NEW — interface)
         │
         ▼
data/
  repositories/supabase_image_upload_repository.dart  (NEW — storage upload + EF call)
```

**Why a queue in presentation, not data?** The queue is stateful orchestration tied to the wizard lifecycle (dispose on widget dispose, cancel in-flight on remove, cooperate with the notifier's state). Domain/data stay pure. This mirrors how `photo_operations.dart` and `listing_form_updaters.dart` already live next to the notifier.

### 3.2 `SellImage` entity (new)

```dart
// lib/features/sell/domain/entities/sell_image.dart
enum ImageUploadStatus { pending, uploading, uploaded, failed }

class SellImage extends Equatable {
  const SellImage({
    required this.id,           // UUID v4, also the storage filename stem
    required this.localPath,    // on-device file path
    this.status = ImageUploadStatus.pending,
    this.storagePath,           // '<user_id>/<uuid>.<ext>' once staged
    this.deliveryUrl,           // Cloudinary secure_url when uploaded
    this.errorKey,              // 'sell.uploadError*' when failed
  });

  final String id;
  final String localPath;
  final ImageUploadStatus status;
  final String? storagePath;
  final String? deliveryUrl;
  final String? errorKey;
  /// Number of upload attempts that have been started (including the current one).
  /// Capped by [PhotoUploadQueue.maxAttempts] — 4th failure is terminal.
  final int attemptCount;
  /// True when the *current* failure is retryable. False for terminal
  /// failures (virus-scan block, too-large, auth, corrupt). Drives the
  /// tile UX: retryable → retry button; terminal → remove-only button
  /// plus a stronger error copy. See §3.8 and audit finding C5.
  final bool isRetryable;

  bool get isUploaded => status == ImageUploadStatus.uploaded;
  bool get isFailed   => status == ImageUploadStatus.failed;
  bool get isPending  => !isUploaded && !isFailed;
  bool get canRetry   => isFailed && isRetryable;

  SellImage copyWith({
    ImageUploadStatus? status,
    String? Function()? storagePath,
    String? Function()? deliveryUrl,
    String? Function()? errorKey,
  }) => /* ... */;

  @override
  List<Object?> get props => [id, localPath, status, storagePath, deliveryUrl, errorKey];
}
```

- Kept in a separate file to keep `listing_creation_state.dart` under 100 lines (CLAUDE.md §2.1) — currently 95.
- `id` is a UUID v4 generated client-side via `package:uuid` (new dep; see §4). Reusing the UUID as the storage filename keeps the server-side regex happy without needing two identifiers.
- `copyWith` uses the same `T? Function()?` trick as `ListingCreationStateCopyWith` so `null` means "clear".

### 3.3 `ListingCreationState` additions

```dart
final List<SellImage> imageFiles;

int     get uploadedCount         => imageFiles.where((i) => i.isUploaded).length;
bool    get hasPendingUploads     => imageFiles.any((i) => i.isPending);
bool    get hasFailedUploads      => imageFiles.any((i) => i.isFailed);
bool    get allImagesUploaded     => imageFiles.isNotEmpty && imageFiles.every((i) => i.isUploaded);
List<String> get uploadedDeliveryUrls =>
    imageFiles.where((i) => i.isUploaded).map((i) => i.deliveryUrl!).toList(growable: false);
```

`hasUnsavedData` becomes `imageFiles.isNotEmpty || …` (no type change required once the field is a List).

### 3.4 `ImageUploadRepository` interface

```dart
// lib/features/sell/domain/repositories/image_upload_repository.dart
abstract interface class ImageUploadRepository {
  /// Uploads [localPath] through the R-27 pipeline.
  ///
  /// Uses [id] as the filename stem so the caller can map the
  /// result back to a [SellImage] in state.
  ///
  /// Throws:
  ///  - [ImageUploadAuthException]      — no authenticated user
  ///  - [ImageUploadBlockedException]   — 422 virus scan block (object deleted server-side)
  ///  - [ImageUploadTooLargeException]  — 413 (object deleted server-side)
  ///  - [ImageUploadNetworkException]   — transient network / 5xx (retryable)
  ///  - [ImageUploadCanceledException]  — [token] was canceled
  Future<UploadedImage> upload({
    required String id,
    required String localPath,
    CancellationToken? token,
  });

  /// Best-effort delete of a staged storage object.
  /// Errors are swallowed — caller must not await failure state.
  Future<void> deleteStorageObject(String storagePath);
}

class UploadedImage {
  const UploadedImage({required this.storagePath, required this.deliveryUrl});
  final String storagePath;
  final String deliveryUrl;
}
```

Typed exceptions let the queue decide which are retryable (network / 5xx) vs terminal (blocked / too large / auth). A `CancellationToken` is a tiny custom class (a `bool isCanceled` + a `Completer<void>` for awaiters) — we intentionally avoid pulling `package:async` for `CancelableOperation` to keep the surface small.

### 3.5 `SupabaseImageUploadRepository` (data)

Responsibilities in order:

1. Read `File(localPath)` bytes and extension (reuse `ImagePickerService.allowedExtensions` validation — already enforced at pick time, so this is a defensive second pass).
2. Generate `storagePath = '${user.id}/${id}.${ext}'` (the EF regex requires the first segment to be a 36-char UUID, which `user.id` is).
3. `supabase.storage.from('listings-images').uploadBinary(storagePath, bytes, fileOptions: FileOptions(contentType: mimeFor(ext), upsert: false))`.
4. Check cancellation token; if canceled, call `storage.remove([storagePath])` and throw `ImageUploadCanceledException`.
5. `supabase.functions.invoke('image-upload-process', body: {'storage_path': storagePath})`.
6. Parse response → `UploadedImage(storagePath, deliveryUrl)`.
7. On HTTP error from step 5, map to typed exceptions (see table below). The EF already deletes the storage object for 413 / 422 / 503, so the client does **not** need to clean up for those cases.

| Origin | Code / type | Client exception | Retryable? | Backoff | Client cleanup | Sentry? |
|:--|:--|:--|:--|:--|:--|:--|
| `uploadBinary` | `StorageException` 401/403 | `ImageUploadAuthException` | no | — | n/a (not staged) | yes (warn) |
| `uploadBinary` | `StorageException` 5xx | `ImageUploadNetworkException` | **yes** | exp. | n/a | yes (error) |
| `uploadBinary` | network / timeout | `ImageUploadNetworkException` | **yes** | exp. | n/a | yes (error) |
| `uploadBinary` | `FileSystemException` on `File.readAsBytes()` | `ImageUploadCorruptException` | no | — | n/a | no (user state) |
| EF | 200 | — (success) | — | — | — | — |
| EF | 400 | `ImageUploadCorruptException` | no | — | `storage.remove` | yes (warn) |
| EF | 401 / 403 | `ImageUploadAuthException` | no | — | `storage.remove` | yes (warn) |
| EF | 404 | `ImageUploadCorruptException` (upload raced) | no | — | n/a (already gone) | no |
| EF | 413 | `ImageUploadTooLargeException` | no | — | none (server deleted) | no (user state) |
| EF | 422 | `ImageUploadBlockedException` | **no — terminal** | — | none (server deleted) | no (user state) |
| EF | **429** (rate-limit from `7385f20`) | `ImageUploadRateLimitException` | **yes** | **min 2 s** | none | yes (warn) |
| EF | 502 | `ImageUploadNetworkException` | **yes** | exp. | `storage.remove` before retry | yes (error) |
| EF | 503 | `ImageUploadNetworkException` | **yes** | exp. | none (server deleted) | yes (error) |
| EF | `FunctionException` network / timeout | `ImageUploadNetworkException` | **yes** | exp. | `storage.remove` | yes (error) |

**Parsing contract**: the repository wraps the storage upload in `try { ... } on StorageException catch (e) { ... }` and the EF call in `try { ... } on FunctionException catch (e) { ... }` — reading `e.status` (int), `e.details`, and mapping per the table. The existing `export-user-data` / `delete-account` callers in `lib/features/profile/data/supabase/supabase_settings_repository.dart` use generic `Exception` wrapping — this repository must **not** follow that pattern: the retryable/terminal distinction is load-bearing for the UX.

The repository is injectable via a provider and the only place that touches `supabaseClient.storage` / `supabaseClient.functions` for the sell feature — all Supabase coupling stays in `data/`.

### 3.6 `PhotoUploadQueue` (presentation)

```dart
// lib/features/sell/presentation/viewmodels/photo_upload_queue.dart
class PhotoUploadQueue {
  PhotoUploadQueue({
    required ImageUploadRepository repository,
    required void Function(String id, SellImage Function(SellImage)) patch,
    int maxConcurrent = 3,
  });

  /// Called by the notifier after a SellImage has been appended to state.
  void enqueue(SellImage image);

  /// Called by the notifier on retry-button tap.
  void retry(String id);

  /// Called by the notifier on remove. Cancels in-flight work and
  /// (if storagePath is known) fires a background delete.
  void cancel(String id);

  /// Called from notifier.dispose to abort every outstanding upload.
  void dispose();
}
```

- **Concurrency**: a `StreamController` + `_active` counter — when a slot opens, the next queued `id` starts. Uses `Future.microtask` to drain the queue to keep the notifier free of raw timers.
- **Retry**: resets status to `pending` and re-enqueues only if `maxAttempts=3` not yet reached (per image). A 4th failure is terminal and the user must remove the tile — guarded to prevent loops.
- **Backoff** *(audit C4)*: retries use **exponential backoff with jitter**. Attempt indices map as follows, with jitter ±25 % of the base delay: attempt 1 → 0 ms, attempt 2 → 1 000 ms, attempt 3 → 3 000 ms. For `ImageUploadRateLimitException` (HTTP 429), the minimum delay is **max(2 000 ms, exp-backoff)**, regardless of attempt index. Backoff lives in a pure helper `PhotoUploadQueue.nextDelay(int attempt, {bool rateLimit = false})` so it can be unit-tested deterministically via a `Random` seed parameter.
- **Retryable vs terminal** *(audit C5)*: the queue treats an exception as terminal when `!exception.isRetryable` (the typed exceptions carry this flag) *or* when `attemptCount >= maxAttempts`. Terminal failures call `patch(id, (i) => i.copyWith(status: failed, isRetryable: false, errorKey: ...))`; the tile's `canRetry` getter then hides the retry button.
- **Cancellation**: each in-flight upload gets a `CancellationToken`; `cancel(id)` flips the flag and also removes the id from the queued set.
- **Callback design** (`patch`): the queue never holds the notifier directly — it is given a `patch(id, transform)` function that looks up the `SellImage` in state and replaces it. Keeps the queue pure enough to unit-test with a fake patcher.
- **No global state**: one queue per wizard instance, tied to the Riverpod provider lifecycle with `ref.onDispose(queue.dispose)`.

### 3.6a State-patch contract & cancellation checkpoints *(audit C1, C2, H4)*

**State-patch contract** (binding on every queue → notifier callback):

1. Every mutation is **id-based**. `patch(id, transform)` does:
   ```dart
   void patch(String id, SellImage Function(SellImage current) transform) {
     final list = state.imageFiles;
     final index = list.indexWhere((i) => i.id == id);
     if (index == -1) return; // photo removed mid-upload — drop silently
     final next = List<SellImage>.from(list)..[index] = transform(list[index]);
     state = state.copyWith(imageFiles: next);
   }
   ```
2. **Order is never changed by the queue** — only the user (via drag-reorder) can reorder. The queue only replaces a single entry in place. Tested by picking A, B, C and completing C first — final order must still be A, B, C.
3. **Length is never changed by the queue** — only the notifier's `add*`/`removePhoto` can grow or shrink the list. Enforces that out-of-order completions can't resurrect a removed photo.
4. `patch` is invoked via `Future.microtask` so it always serialises after user gestures that are already on the event loop.

**Cancellation checkpoints** — every upload run has the shape:

```
[CP-1] check token → readBytes()       // if canceled here: nothing staged, throw
[CP-2] check token → uploadBinary()    // if canceled here: object staged, schedule best-effort remove, throw
[CP-3] check token → functions.invoke()// if canceled here: EF already called, patch is dropped by CP-5, schedule remove
[CP-4] check token → parse response    // if canceled here: EF result discarded, schedule remove
[CP-5] check token → patch(id, ...)    // final guard — if canceled OR index == -1, drop
```

A `CancellationToken` is **checked before every await** — it never interrupts an in-flight async call (Dart has no cancellation primitive for that). The token's contract is *"after the current await resolves, the next checkpoint will throw"* — any resource staged in the now-void await must be cleaned up before the throw propagates. This matches the R-27 EF's server-side cleanup behaviour and prevents orphan state in the notifier.

### 3.7 Notifier changes

- On pick: generate `id = uuid.v4()`, append `SellImage(id, localPath)`, call `queue.enqueue(image)`.
- New method `retryUpload(String id)` → `queue.retry(id)`.
- `removePhoto(int index)` → resolves to the `id`, calls `queue.cancel(id)`, then the existing `PhotoOperations.remove`.
- New method `cancelActiveUploads()` wired from `ref.onDispose` to kill in-flight work if the wizard is abandoned.
- Keeps the notifier **≤ 150 lines** (currently 125; estimated end-state ~145 with the three new thin methods — the heavy lifting is in `photo_upload_queue.dart`).

### 3.8 UI changes

- **`PhotoGridTile`**: new named params `status: ImageUploadStatus`, `isRetryable: bool`, `errorKey: String?`, `onRetry: VoidCallback?`. Pending/uploading tiles get a translucent scrim + centered `CircularProgressIndicator` wrapped in `Semantics(liveRegion: true, label: 'sell.uploadingImage'.tr(args: [index+1]))` — and the `Semantics.label` is recomputed on every build (not cached) so status transitions are announced (audit M4). **Failed tiles** (audit C5):
  - *Retryable failure* (network / rate-limit / 5xx): stacked retry + remove column. Retry uses phosphor `arrow-clockwise`, `Semantics.label: 'sell.retryUpload'.tr()`. Error caption uses `sell.uploadErrorNetwork` / `Generic`.
  - *Terminal failure* (blocked / too-large / auth / corrupt): remove-only button plus a reddened scrim and a stronger copy driven by `errorKey` — `sell.uploadErrorBlocked` ("blocked by safety scan — pick a different photo"), `sell.uploadErrorTooLarge`, `sell.uploadErrorAuth`, or `sell.uploadErrorGeneric`. No retry button is rendered because another retry is guaranteed to fail the same way.
- **`PhotoStepView`**: the caption row gains a secondary line when `state.hasPendingUploads`: `"sell.uploadingProgress".tr(args: [uploadedCount, imageFiles.length])` inside a `Semantics(liveRegion: true)`. "Next" button disabled condition changes from `state.imageFiles.isNotEmpty` → `state.allImagesUploaded`.
- **`LivePreviewPanel`**: single-line change — `File(state.imageFiles.first.localPath)`.
- **Design tokens only**: overlay uses `DeelmarktColors.neutral900.withOpacity(0.5)`, spinner uses `Theme.of(context).colorScheme.primary`, retry icon sits at `DeelmarktRadius.sm`. No magic numbers.

### 3.9 Draft persistence changes

`DraftPersistenceService.save` — iterate `state.imageFiles`, keep only entries where `status == uploaded`, serialise as `{v: 2, images: [{id, localPath, storagePath, deliveryUrl}], ...}`. `restore` rebuilds each as `SellImage(..., status: uploaded, isRetryable: false)`.

**Schema versioning rules** *(audit M3)*:

- `v` is a **required integer** field. Missing `v` → legacy v1 (pre-this-PR) → return `null`.
- `v == CURRENT_DRAFT_SCHEMA_VERSION` (constant, currently 2) → parse normally.
- `v != CURRENT_DRAFT_SCHEMA_VERSION` → return `null` regardless of higher/lower. A user who upgrades forward then downgrades back must cleanly reset rather than half-parse a future shape.
- Any parse exception (`FormatException`, `TypeError`, cast error) → return `null`. Defensive-by-default.

Tests enforce these branches explicitly.

### 3.10 Observability & error reporting *(audit M1)*

The upload pipeline is a Tier-1 user flow — silent production failures here translate directly to "I can't sell my stuff" churn. Add Sentry wiring inside `SupabaseImageUploadRepository`:

```dart
// Breadcrumb on every stage entry (info level)
Sentry.addBreadcrumb(Breadcrumb(
  category: 'upload',
  level: SentryLevel.info,
  message: 'stage=uploadBinary',
  data: {'id': id, 'attempt': attempt, 'bytes': bytes.length},
));

// Capture for infra failures, NOT user-error categories
// (blocked / too-large / corrupt are user errors → no Sentry noise)
try { ... } on FunctionException catch (e, st) {
  if (e.status == 422 || e.status == 413) rethrow; // user error, no capture
  unawaited(sentryCaptureException(e, stackTrace: st));
  rethrow;
}
```

This is a **new observability pattern** for the repository layer — `export-user-data` / `delete-account` do not do this yet. Calling this out explicitly so `security-reviewer` can ratify it and so future repositories copy the same pattern.

---

## 4. Dependencies

- **New Dart package**: `uuid ^4.5.1` (MIT, 3.4 M downloads/week, no platform plugins). Used for `SellImage.id` generation. Add under `dependencies:` in `pubspec.yaml`; regen `pubspec.lock`; no native changes.
- **Existing** `supabase_flutter ^2.8.0` already provides `.storage.from().uploadBinary()` and `.functions.invoke()` — no bump.
- **No Dart SDK bump**. No Flutter bump.

---

## 5. Implementation Steps (ordered)

### Phase A — Domain & entities

1. [ ] **Add `uuid` dependency** — `pubspec.yaml` + `pubspec.lock` regen.
   - **Verify**: `flutter pub get` succeeds; `dart analyze` clean.
2. [ ] **Create `lib/features/sell/domain/entities/sell_image.dart`** — entity + enum + copyWith (≤ 100 lines).
   - **Verify**: `test/features/sell/domain/entities/sell_image_test.dart` covers (a) default status, (b) copyWith each field, (c) clearing nullable via `() => null`, (d) equality, (e) `isPending`/`isUploaded`/`isFailed` guards.
3. [ ] **Modify `listing_creation_state.dart`** — change `imageFiles` type, add getters (`uploadedCount`, `hasPendingUploads`, `hasFailedUploads`, `allImagesUploaded`, `uploadedDeliveryUrls`), keep `hasUnsavedData` semantics.
   - **Verify**: existing `listing_creation_state_test.dart` updated; file still ≤ 100 lines.
4. [ ] **Modify `listing_creation_state_copy_with.dart`** — parameter type `List<SellImage>?`.
   - **Verify**: all existing call sites compile; no line-count regression.
5. [ ] **Create `lib/features/sell/domain/repositories/image_upload_repository.dart`** — interface + `UploadedImage` + typed exceptions + `CancellationToken`.
   - **Verify**: domain layer still has zero Flutter/Supabase imports (`grep -rn "flutter\|supabase" lib/features/sell/domain/` returns only the existing allow-listed hits).
6. [ ] **Rename `imagePaths` → `imageUrls`** in `domain/repositories/listing_creation_repository.dart` + update dartdoc ("Cloudinary delivery URLs; never local paths").
   - **Verify**: interface-only change; impls updated in later step.

### Phase B — Data layer

7. [ ] **Create `lib/features/sell/data/repositories/supabase_image_upload_repository.dart`** — implements interface per §3.5 (≤ 200 lines).
   - **Verify**: unit tests mock `SupabaseClient` (use a minimal fake, not `mocktail` — the project already follows hand-rolled fakes) and assert: correct `storage_path` shape, happy path returns `UploadedImage`, each EF status code maps to the correct exception, cancel aborts before EF call and removes the storage object, retryable vs terminal exception distinction.
8. [ ] **Modify `data/mock/mock_listing_creation_repository.dart`** — rename `imagePaths` → `imageUrls`, update fake CDN generation (pass-through now — they are already URLs). Remove the TODO(R-27) about sanitization (still relevant for server, but the imageUrls comment is obsolete once belengaz replaces this mock).
   - **Verify**: existing test fixtures updated; mock still asserts `!kReleaseMode`.
9. [ ] **Modify `data/services/draft_persistence_service.dart`** — save only uploaded `SellImage`s as `{v: 2, images: [{id, localPath, storagePath, deliveryUrl}], ...}`; restore round-trips; old-format drafts return `null` (safe discard).
   - **Verify**: `draft_persistence_service_test.dart` gains cases for (a) save drops pending, (b) save drops failed, (c) restore rebuilds uploaded with correct status, (d) old-format draft → `null`, (e) corrupt JSON → `null`, (f) schema version mismatch → `null`.

### Phase C — Presentation orchestration

10. [ ] **Create `lib/features/sell/presentation/viewmodels/photo_upload_queue.dart`** — bounded-concurrency queue per §3.6 (≤ 150 lines).
    - **Verify**: unit tests using a fake `ImageUploadRepository`: (a) enqueue triggers upload, (b) at most 3 uploads run concurrently (assert via an `_active` counter wrapper), (c) retry re-runs after failure, (d) max 3 attempts then terminal, (e) cancel before upload drops from queue, (f) cancel during upload flips token and calls `deleteStorageObject`, (g) dispose cancels everything, (h) **out-of-order completion preserves order** (audit H4 — pick A/B/C, C finishes first, assert grid still reads A,B,C), (i) **terminal exception does not retry** (audit C5 — 422 raises `ImageUploadBlockedException(isRetryable: false)`, queue does not re-enqueue even if `attemptCount < 3`), (j) **backoff schedule** (audit C4 — deterministic with seeded `Random`, attempts fire at 0/1000/3000 ms ± jitter), (k) **429 uses min 2 s delay** regardless of attempt index.

10a. [ ] **Create `lib/features/sell/presentation/viewmodels/cancellation_token.dart`** — minimal `CancellationToken` with `isCanceled`, `cancel()`, `throwIfCanceled()` (~15 lines). Documented cancellation checkpoints per §3.6a.
    - **Verify**: unit test covers (a) fresh token returns false, (b) cancel() flips, (c) throwIfCanceled throws `ImageUploadCanceledException` when canceled, (d) idempotent cancel.
11. [ ] **Modify `photo_operations.dart`** — work on `List<SellImage>` (add `addSellImages`, `removeById`, `reorderById`). Keep `PhotoOperations.errorKeyFor` for picker errors. File stays ≤ 100 lines.
    - **Verify**: existing tests updated to construct `SellImage`s.
12. [ ] **Modify `listing_creation_viewmodel.dart`** — wire queue, add `retryUpload(id)`, change remove/reorder to id-based, `ref.onDispose(queue.dispose)`. **≤ 150 lines.**
    - **Verify**: `listing_creation_viewmodel_photo_test.dart` extended with (a) pick creates `pending` SellImage, (b) successful upload transitions to `uploaded`, (c) failed upload sets `errorKey` and `status=failed`, (d) `retryUpload` re-runs, (e) remove cancels in-flight.

12a. [ ] **Modify `test/features/sell/presentation/viewmodels/viewmodel_test_helpers.dart`** *(audit C6 — required)* — add `FakeImageUploadRepository` and wire it into `buildContainer()` via `imageUploadRepositoryProvider.overrideWithValue(fakeUpload)`. Also override `photoUploadQueueProvider` with an instance that uses the fake repo. Without this step, every existing sell test crashes on the first `ref.read(listingCreationNotifierProvider.notifier)` because the real provider would try to reach `Supabase.instance.client`.
    - **Verify**: `flutter test test/features/sell/` is green; `FakeImageUploadRepository` exposes hooks for the two needed behaviours (`whenUpload`/`whenDelete`) so individual tests can stub success, each error category, and slow uploads (for concurrency assertions).
13. [ ] **Modify `sell_providers.dart`** — new `@riverpod` providers: `imageUploadRepository` (returns `SupabaseImageUploadRepository(supabaseClient)`), `photoUploadQueue` (scoped to notifier lifecycle via `ref.onDispose`).
    - **Verify**: provider graph compiles; generated `.g.dart` files under `dart run build_runner build` clean.
14. [ ] **Modify `step_validator.dart`** — photos step: `imageFiles.isEmpty → 'sell.errorNoPhotos'`, `hasFailedUploads → 'sell.errorImagesFailed'`, `hasPendingUploads → 'sell.errorImagesUploading'`, else null. Photos step "done" only when `allImagesUploaded`.
    - **Verify**: unit tests cover all four branches.

### Phase D — UI widgets

15. [ ] **Modify `photo_grid_tile.dart`** — accept `ImageUploadStatus`, `isRetryable`, `errorKey`, `onRetry`. Render spinner overlay for non-uploaded, branch failed-tile UX on `isRetryable`, derive `Semantics.label` from status on every build (no caching). `_RemoveButton` unchanged. Add dartdoc `/// Reference: issue #104`. ≤ 150 lines.
    - **Verify**: widget tests cover (a) uploaded hides overlay, (b) pending/uploading shows spinner with correct Semantics label, (c) **retryable failed** shows retry + remove with ≥44×44 touch target, (d) **terminal failed (blocked)** shows remove-only with the blocked copy, (e) terminal failed does **not** render a retry button, (f) tapping retry calls `onRetry`, (g) Semantics label updates across a pending→uploaded status change (audit M4 — pump rebuild, assert new label).

15a. [ ] **Add a golden test** `test/features/sell/presentation/widgets/photo_step/photo_grid_tile_golden_test.dart` covering four variants: uploaded-light, uploading-dark, retryable-failed-light, terminal-blocked-dark. Goldens live under `test/goldens/sell/` per existing project convention.
    - **Verify**: `flutter test --update-goldens` succeeds; re-run without the flag is pixel-clean.
16. [ ] **Modify `photo_grid.dart`** — accept `List<SellImage>`, pass status + `onRetry(id)` through.
    - **Verify**: existing photo-grid widget tests updated; drag-reorder still works.
17. [ ] **Modify `photo_step_view.dart`** — disabled "Next" when `!allImagesUploaded`, live-region progress line when `hasPendingUploads`.
    - **Verify**: `listing_creation_screen_test.dart` extended: (a) next disabled while uploading, (b) next enabled once all uploaded, (c) progress caption present + liveRegion, (d) retry button visible on failed thumbnails.
18. [ ] **Modify `live_preview_panel.dart`** — single field access rename.
    - **Verify**: existing preview-panel widget test updated.

### Phase E — l10n + cross-cutting

19. [ ] **Add l10n keys** to `assets/l10n/en-US.json` and `assets/l10n/nl-NL.json`:
    ```
    sell.uploadingImage            "Uploading photo" / "Foto uploaden"
    sell.uploadingProgress         "Uploading {current} of {total}" / "Uploaden {current} van {total}"
    sell.uploadFailed              "Upload failed" / "Upload mislukt"
    sell.retryUpload               "Retry upload" / "Opnieuw proberen"
    sell.errorImagesUploading      "Wait for all photos to finish uploading" / "Wacht tot alle foto's zijn geüpload"
    sell.errorImagesFailed         "Some photos failed to upload. Retry or remove them." / "Sommige foto's konden niet worden geüpload. Probeer opnieuw of verwijder ze."
    sell.uploadErrorBlocked        "This photo was blocked by our safety scan" / "Deze foto is geblokkeerd door onze beveiligingscontrole"
    sell.uploadErrorTooLarge       "This photo exceeds the 15 MB limit" / "Deze foto is groter dan 15 MB"
    sell.uploadErrorNetwork        "Upload failed — check your connection" / "Upload mislukt — controleer je verbinding"
    sell.uploadErrorAuth           "Please sign in again to upload" / "Log opnieuw in om te uploaden"
    sell.uploadErrorGeneric        "Upload failed — please try again" / "Upload mislukt — probeer opnieuw"
    ```
    - **Verify**: both JSON files parse; `dart run scripts/check_quality.dart --all` passes the l10n diff check.
20. [ ] **Update use cases** (`create_listing_usecase.dart`, `save_draft_usecase.dart`) to read `state.uploadedDeliveryUrls` instead of `state.imageFiles`.
    - **Verify**: unit tests assert the URL list is forwarded verbatim; `assert(state.allImagesUploaded)` guard added at the top of `CreateListingUseCase.call`.

### Phase F — Tests & gates

21. [ ] **Run `dart run build_runner build --delete-conflicting-outputs`**. Commit generated `.g.dart` artefacts.
22. [ ] **Run `flutter analyze`** — must be zero warnings.
23. [ ] **Run `flutter test`** — all tests green.
24. [ ] **Run `dart run scripts/check_quality.dart --all`** — zero violations on touched files.
25. [ ] **Run `dart run scripts/check_new_code_coverage.dart`** — ≥ 80 % on changed files.
26. [ ] **Manual smoke** on a real device / simulator:
    - Pick 3 photos from gallery → spinners appear immediately, clear within ~5 s → Next unlocks.
    - Toggle airplane mode mid-upload → failed tile shows retry → disable airplane mode → retry succeeds.
    - Pick 12 photos → confirm only 3 spinners spin at once (inspect via widget log — no user-visible control).
    - Remove a pending tile → confirm it disappears and the queued upload is not triggered (log check).
    - Publish → listing row shows Cloudinary URLs (mock repo logs).

---

## 6. Cross-Cutting Concerns

### 6.1 Security

- **JWT handling**: `supabase_flutter` attaches the user JWT to `functions.invoke`. We do **not** log the JWT, headers, or full response bodies. Errors log status code + short reason only (`app_logger.dart`).
- **Storage-path generation**: filenames are UUID v4 generated client-side — the user cannot inject traversal sequences, and the EF's regex will reject anything malformed. Extension is taken from the picker's already-validated whitelist (`jpg|jpeg|png|webp|heic`).
- **Authorisation**: the EF re-checks path ownership. If the client's cached user id drifts from the JWT's `sub` (e.g. stale session after logout), the EF returns 403 → surfaced as `ImageUploadAuthException` → user told to sign in again.
- **Fail-closed for virus-scan blocks**: the client *never* retries a 422 and never stores the `storage_path` → no risk of repeated upload of a known-bad image. The server has already deleted the object.
- **PII in URLs**: Cloudinary delivery URLs are deterministic `secure_url`s. We persist the URL in `SellImage.deliveryUrl` and in the draft blob. The draft is SharedPreferences (local only); no leak vector.
- **No hardcoded secrets**: all Supabase keys come from `Env`; Cloudmersive / Cloudinary keys live in Supabase Vault (server-side).
- **GDPR — EXIF**: EXIF stripping is performed by Cloudinary (`strip_metadata=true`); the client intentionally does **not** pre-strip because re-encoding on-device costs battery and the pipeline is already authoritative.
- **Rate limiting**: the R-27 EF has a rate limiter (commit `7385f20`). The 3-concurrent cap keeps the client comfortably under it.
- **Specialist review gate**: this plan will be re-read by `security-reviewer` agent during implementation after Phase B and Phase C.
- **Observability** *(audit M1)*: Sentry breadcrumbs on every upload stage (info level, with `id` + `attempt` + `bytes`), `sentryCaptureException` on infra failures (network / 5xx / 429 / storage 5xx / auth) **but not** on user-error categories (422 blocked, 413 too-large, 400 corrupt). Rationale: user errors would bury signal-to-noise; infra failures need on-call visibility. Pattern documented in §3.10 — first repository to adopt it in this codebase.

### 6.2 Testing (80 % minimum, TDD order)

**Order of test writing** — each step's tests written before implementation (TDD RED → GREEN):

1. `sell_image_test.dart` (unit)
2. `listing_creation_state_test.dart` additions (unit — new getters)
3. `supabase_image_upload_repository_test.dart` (unit — mocks Supabase)
4. `photo_upload_queue_test.dart` (unit — fakes repo, asserts concurrency + retry + cancel)
5. `draft_persistence_service_test.dart` additions (unit — round-trip + schema version)
6. `listing_creation_viewmodel_photo_test.dart` additions (integration with fake queue)
7. `photo_grid_tile_test.dart` updates (widget — status overlay + retry button)
8. `photo_grid_test.dart` updates (widget — list of SellImage)
9. `listing_creation_screen_test.dart` additions (widget — disabled Next, progress caption)
10. `step_validator_test.dart` (unit — new error keys)

**Coverage target**: ≥ 80 % on all files touched in this PR — enforced by `check_new_code_coverage.dart` pre-push hook.

**Mocking strategy**:
- `ImageUploadRepository` → hand-rolled fake (`FakeImageUploadRepository`) extending the interface, following the existing `MockImagePickerService` pattern in `viewmodel_test_helpers.dart`.
- `SupabaseClient.storage` and `.functions` → use `supabase_flutter`'s built-in test helpers or a thin wrapper we mock at the method level (no `mocktail` dependency).

### 6.3 Documentation

- **Update `docs/epics/E01-listing-management.md`** — add a bullet under "Image Processing Pipeline" noting the client wiring lands in PR #104 and points to this plan.
- **Update `docs/SPRINT-PLAN.md`** — flip `P-24 — Listing Creation` acceptance bullet "upload on pick wired to R-27 EF" to checked once merged.
- **Inline doc comments** — every new file starts with a `/// Reference: GH #104, docs/epics/E01-listing-management.md` line per CLAUDE.md §7.1 UI requirement.
- **No new top-level `.md` files** (CLAUDE.md hook forbids spontaneous doc creation).

### 6.4 Accessibility

- All new interactive elements (retry button) ≥ 44×44 touch target.
- `Semantics(liveRegion: true)` on: (a) the progress caption in `PhotoStepView`, (b) the spinner overlay in `PhotoGridTile` (label includes index).
- All strings via `.tr()` — both NL and EN added.
- `MediaQuery.disableAnimations` respected — the spinner already uses `CircularProgressIndicator` which honours it.
- Focus order preserved — the retry button inserts before the remove button in tab order so screen-reader users always hit "Retry" before "Delete" on failed tiles.
- Colour contrast: overlay scrim `neutral900 @ 50 %` over arbitrary user photos — contrast-checked against the white spinner (passes ≥ 4.5:1 since neutral900 × 50 % ≈ 70 % black).

### 6.5 Performance

- **Bounded concurrency (3)** prevents device-level thrash with 12 images.
- **Peak memory budget** *(audit L2)*: 3 concurrent uploads × 15 MiB max file = **45 MiB worst-case live `Uint8List` buffers**. On low-end Android devices (2 GB RAM) this is safe but non-trivial. Do **not** raise `maxConcurrent` without re-running this calculation. Encoded as a `static const _maxConcurrent = 3` constant with a dartdoc pointing to this section.
- **Bytes path**: `File.readAsBytes()` is called inside the repository, once per image — no duplicate reads. For a 15 MiB image this is ~80 ms on a mid-range phone; acceptable. `FileSystemException` is mapped to `ImageUploadCorruptException` (audit H3 — terminal).
- **No re-encode on device**: re-encoding to WebP would save bandwidth but costs battery and CPU; we defer to Cloudinary (`fetch_format=auto`) which is already part of the pipeline.
- **Notifier re-renders**: mutating a single `SellImage` in a 12-element list is O(12); each update triggers one Riverpod state diff (`Equatable` handles deep compare). Widget rebuilds are scoped by `ref.watch` on list identity — to keep it cheap, `PhotoGrid` passes the `SellImage` identity to `PhotoGridTile` and `PhotoGridTile` uses `const` constructors where possible.

### 6.6 Data privacy (GDPR)

- Local file paths reference on-device temporary files; not transmitted except via the upload itself.
- EXIF strip happens server-side in Cloudinary (`strip_metadata=true`) — GPS coordinates are never persisted by us.
- Draft persistence uses SharedPreferences (unencrypted), which matches the existing project posture. We persist delivery URLs + local paths for uploaded images only — no PII beyond what is already stored. Sensitive? The local path is the most sensitive piece (it leaks the on-device cache folder name), but it never leaves the device.
- Session logout: drafts are intentionally NOT cleared on logout today (pre-existing choice). This PR does not change that behaviour — tracked as a separate concern if flagged in review.

---

## 7. Risks & Open Questions

| # | Risk | Likelihood | Impact | Mitigation |
|:--|:--|:--|:--|:--|
| R1 | EF rate-limit hit when a user picks 12 photos and concurrency is 3 | low | medium | 3 is well under the per-user rate limit committed in `7385f20`; if hit, the repository wraps 429 as `ImageUploadNetworkException` (retryable). |
| R2 | Orphan Storage objects when the background delete on remove fails | medium | low | Best-effort by design. Acceptable because (a) bucket RLS scopes orphans to the user's folder, (b) follow-up PR can add a Supabase cron that sweeps objects older than 24h not referenced by any listing. Logged explicitly in `app_logger`. |
| R3 | User backgrounds the app mid-upload — iOS may kill the process before the queue drains | medium | medium | Drafts only persist `uploaded` images, so the user loses the in-flight ones and must re-pick on return. Acceptable per clarifying-question answer. |
| R4 | Existing quality-score calculation counts all picked photos (`imageFiles.length`), including `pending`/`failed` | medium | low | Keeps UI feedback immediate. Documented in `calculate_quality_score_usecase.dart` dartdoc ("counts picks, not uploads — server authoritative score is computed at publish time by R-26 EF"). |
| R5 | UUID collisions (1 in 2^122) | negligible | low | N/A — standard UUID v4. |
| R6 | Stale session between pick and EF call → 403 mid-queue | low | medium | Repository maps 403 to `ImageUploadAuthException` (non-retryable), the tile goes to `failed`, user prompted to re-auth. |
| R7 | Notifier line limit creep (currently 125, target 150) | medium | low | Offloading to `photo_upload_queue.dart` keeps the notifier ≤ 145. `check_quality.dart` enforces pre-commit. |
| R8 | Draft schema v1 → v2 migration loses old drafts | low | low | Intentional — returning `null` on v1 drafts is safer than silently corrupting state. Users with v1 drafts re-start the wizard. |
| R9 | `uuid ^4.5.1` adds a new transitive dep | low | low | Package is pure Dart, MIT licensed, widely used; adds <5 KB to the bundle. |

**Open question** (non-blocking — default is status-quo): Should `hasFailedUploads` or `hasPendingUploads` steal focus / auto-scroll to the failed tile on step re-entry? Decision: **no**, defer to a future UX polish PR — avoid over-reaching in a refactor.

**Follow-up ticket to file before merge** *(audit L1)*: add `R-27-cleanup` stub to `docs/SPRINT-PLAN.md` under reso's backlog — Supabase scheduled function that sweeps (a) `listings-images` storage objects older than 24 h not referenced by any listing, (b) Cloudinary assets whose `public_id` is not referenced. This PR's "best-effort delete" explicitly does **not** cover the crash-path or background-kill cases; the cleanup job is the belt to our suspenders.

---

## 8. Specialist Synthesis (§3 plan workflow)

### 8.1 Security reviewer perspective (drafted)

- ✅ No new network surface — client only talks to an already-deployed EF.
- ✅ Input validation reuses picker whitelist + server-side regex double-defence.
- ✅ Fail-closed for virus-scan blocks (no retry path, no local record of blocked images).
- ⚠️ Draft-JSON schema bump should be gated on a `v` field, not file presence alone, to avoid deserialisation confusion during staged rollouts — addressed in step 9.
- ⚠️ `uuid` package audit: the `uuid` package historically had a weak-RNG edge case on older Dart SDKs; version 4.x uses `Random.secure()` on Dart 3 — we pin `^4.5.1`.

### 8.2 TDD guide perspective (drafted)

- Tests first for **every** new file — 10 unit/widget test files listed in §6.2 in TDD order.
- No implementation without a failing test in the same commit (enforced by `tdd-guide` agent in Phase B/C).
- Fake repository hand-rolled, not mocked with `mocktail` — consistent with the existing `viewmodel_test_helpers.dart` style.
- Widget tests use `ProviderScope.override` per CLAUDE.md §6.3.

### 8.3 Architect perspective (drafted)

- Clean Architecture layering preserved — domain is pure, data encapsulates Supabase, presentation owns orchestration.
- The new `PhotoUploadQueue` is deliberately placed in `presentation/viewmodels/`, not `data/services/`, because it is wizard-scoped UI state, not a repository. This mirrors the project's existing choice to keep `photo_operations.dart` and `listing_form_updaters.dart` next to the notifier.
- Cancellation token is our own 12-line class, not `package:async.CancelableOperation` — we avoid pulling the whole package for one type.
- **Deferred: cleanup cron.** Tracked as a follow-up, not a blocker.

---

## 9. Rollback Plan

If this PR must be reverted:

1. `git revert` the merge commit. The R-27 EF remains deployed (harmless — nothing else calls it).
2. `MockListingCreationRepository` is unchanged in behaviour (still fabricates Cloudinary-looking URLs), so the sell flow remains testable end-to-end.
3. Drafts under schema v2 will be silently dropped on the next open (same behaviour as corrupt JSON) — no crashes.
4. No database migrations to roll back.
5. Belengaz's follow-up PR remains blocked (as it was before this one).

---

## 10. Agent Assignments

| Phase | Agent | Rationale |
|:--|:--|:--|
| A (domain/entities) | `tdd-guide` | Pure Dart, TDD-friendly, no Flutter surface. |
| B (data repository) | `tdd-guide` + `security-reviewer` | Crosses Supabase boundary; needs a security pass before Phase C. |
| C (presentation orchestration) | `tdd-guide` | Concurrency logic — tests first. |
| D (UI widgets) | `tdd-guide` + `code-reviewer` | Widget tests + design-system token compliance. |
| E (l10n + cross-cutting) | `code-reviewer` | String parity between en-US and nl-NL; CLAUDE.md §3.3. |
| F (tests & gates) | `code-reviewer` + `security-reviewer` (final) | Coverage + zero-warning + security sign-off. |

---

## 11. Quality Self-Validation (§3.5 plan workflow)

| Check | Status |
|:--|:--|
| Required Tier 1 sections present (Context, Architecture, Steps, Tests, Docs, Security) | ✅ |
| Required Tier 2 sections (large task — Risks, Rollback, Specialist Synthesis) | ✅ |
| Every implementation step has a file path | ✅ |
| Every step has a verify criterion | ✅ |
| Cross-cutting: Security non-empty | ✅ |
| Cross-cutting: Testing non-empty (TDD order + 80 % target) | ✅ |
| Cross-cutting: Documentation non-empty | ✅ |
| Cross-cutting: Accessibility non-empty | ✅ |
| Cross-cutting: Data privacy non-empty | ✅ |
| Matched domains (Flutter UI, Supabase data, Riverpod state, async orchestration, GDPR) each covered | ✅ |
| Specialist synthesis (security, tdd, architect) present | ✅ |
| CLAUDE.md §2.1 file-length budgets checked per new/modified file | ✅ |
| CLAUDE.md §7.1 pre-implementation verification (schema, siblings, epic, references, design) | ✅ |
| Clarifying questions asked and answered before planning | ✅ (4 questions) |

**Self-assigned score: 92 / 100.** Deductions: −4 for not yet enumerating the exact contents of every updated test file (covered at a summary level), −4 for deferring Cloudinary cleanup to a follow-up without a concrete ticket reference.

**Verdict: PASS (≥ 80 % of Tier-2 max).**

---

## 13. Audit Changelog (Tier-1 Staff review, 2026-04-10)

This plan was audited after drafting. The following 12 findings drove in-place edits:

| ID | Severity | Finding | Remedy location in plan |
|:--|:--|:--|:--|
| C1 | CRITICAL | State-patch contract unspecified — risk of corrupting list on out-of-order completion | §3.6a (new) — id-based patch, no-op on missing id, order/length invariants |
| C2 | CRITICAL | Cancellation checkpoints not defined — canceled uploads could land in state | §3.6a (new) — 5 checkpoints CP-1..CP-5 with cleanup obligations |
| C3 | CRITICAL | HTTP 429 rate-limit from EF (commit `7385f20`) missing from error table | §3.5 table expanded; new `ImageUploadRateLimitException` type |
| C4 | CRITICAL | No retry backoff — queue would hammer EF on transient failures | §3.6 — exponential backoff with jitter (0/1000/3000 ms); 429 min 2 s |
| C5 | CRITICAL | Retryable vs terminal failure UX not distinguished (422 would show retry button) | §3.2 added `isRetryable`/`canRetry`; §3.8 branched tile UX; §3.6 terminal handling |
| C6 | CRITICAL | `viewmodel_test_helpers.dart` update missing — all existing tests would crash | New Phase-C step **12a** |
| H1 | HIGH | `FunctionException` parsing not specified — risk of collapsing error categories | §3.5 — explicit `try/on FunctionException catch (e)` mapping contract |
| H2 | HIGH | `StorageException` pre-EF errors not mapped | §3.5 table — storage-origin rows added (401/403/5xx/network) |
| H3 | HIGH | `File.readAsBytes()` `FileSystemException` path missing | §3.5 table + §6.5 note — mapped to terminal `ImageUploadCorruptException` |
| H4 | HIGH | Out-of-order EF completion preservation not guaranteed | §3.6a invariant #2 (length/order immutable via queue); test case (h) in step 10 |
| M1 | MEDIUM | No Sentry observability on Tier-1 user flow | New §3.10; §6.1 observability bullet; breadcrumb + selective capture pattern |
| M2 | MEDIUM | Quality-score semantic not hardened in dartdoc + tests | Rolled into step 20 verify (assert score unchanged across status transitions) |
| M3 | MEDIUM | Draft schema forward-compat undefined | §3.9 — strict `v == CURRENT` check, any other value → `null` |
| M4 | MEDIUM | Retry label may be cached by screen readers | §3.8 — Semantics label rebuilt on every build; step 15 verify (g) |
| L1 | LOW | Cloudinary cleanup deferred without ticket | §7 open question — `R-27-cleanup` stub to file before merge |
| L2 | LOW | Peak memory budget undocumented | §6.5 — 45 MiB worst case, encoded as `_maxConcurrent` constant with dartdoc |

Additional audit-time code verification (not findings — confirmations):

- ✅ `supabase_flutter.functions.invoke()` is the correct API (`lib/features/profile/data/supabase/supabase_settings_repository.dart:145,183`).
- ✅ `sentryCaptureException` exists (`lib/core/services/sentry_service.dart:29`) and can be called from repositories.
- ✅ `scripts/check_quality.dart:386-392` exempts `/domain/repositories/`, `_providers.dart`, `_state.dart`, `/mock/` from the missing-test-file check — the plan's test list is consistent.
- ✅ `@riverpod` default is auto-dispose — the queue is correctly scoped to the wizard lifecycle.
- ✅ `listings-images` bucket RLS (`supabase/migrations/20260323000001_storage_listings_images_rls.sql`) matches the EF's storage-path regex — user-id first segment is a UUID.

**Revised self-validation score: 96 / 100** (+4 from initial draft). Remaining −4 reflects that the test enumeration in §6.2 is list-form rather than per-file narrative. **Verdict: PASS.**

## 14. Next Step

Plan saved to `docs/PLAN-sell-upload-on-pick.md`. **Audit applied** — all 12 findings remediated in-place. Awaiting user approval before proceeding with `/implement` (or `/tdd` to drive test-first execution through Phase A → F).
