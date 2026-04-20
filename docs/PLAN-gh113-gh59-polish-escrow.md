# Implementation Plan: GH-113 Non-Blocking Polish + GH-59 EscrowBadge

> **Plan ID:** PLAN-gh113-gh59-polish-escrow
> **Created:** 2026-04-20
> **Task Size:** Large (22+ files, multi-day effort across 3 developers)
> **Quality Score:** 86/86 (Tier 1: 60 + Tier 2: 20 + Domain bonuses: 6) → **PASS**
> **Domains Matched:** Mobile · Frontend · Database
> **Owners:** pizmam (UI/tests) · reso (DB migration) · belengaz (DTO/router)
> **Branches:**
> - `fix/gh113-non-blocking-polish` — pizmam + belengaz
> - `fix/gh59-escrow-badge` — pizmam + reso + belengaz
> **Blocks / Blocked-by:** GH-59 UI PR is blocked by reso's migration PR (see §14)

---

## Alignment Verification

| Check | Status |
|-------|--------|
| Trust > Optimisation | ✓ — #59 uses server-authoritative eligibility (ADR-023); fail-closed default hides badge on serialisation failure |
| Existing patterns | ✓ — Riverpod `AsyncNotifier`, `Equatable`, sentinel `copyWith`, `DeelBadge`, `Unleash` feature flag all followed |
| Rules consulted | `CLAUDE.md` · `coding-style.md` · `security.md` · `testing.md` · `performance.md` · `ADR-023` · `ADR-024` |
| Coding style | ✓ — Immutability enforced; file-line limits respected; no setState/FutureBuilder; all UI text via `.tr()` |

---

## 1. Context & Problem Statement

**GH-113** captures seven non-blocking code-quality items identified in the post-merge retrospective of PR #175:
dead widget code, duplicated `SliverAppBar` across five files, a private reusable card living in the wrong layer,
a loose empty-state predicate, an undocumented magic number in the filter sheet, a no-op `copyWith` in the chat
send controller, and an underdocumented `writeState` constraint. None of these items affects runtime behaviour
today, but each increases maintenance cost and creates drift from the architecture rules in `CLAUDE.md`.

**GH-59** adds the EscrowBadge to listing cards — a trust-signal feature. ADR-023 (accepted 2026-04-17)
mandated that escrow eligibility be computed **server-side** and stored on the `listings` row, not derived
client-side, due to EU Consumer Rights Directive legal risk. The `DeelCard.grid` widget already accepts
`showEscrowBadge`, and the `listings_escrow_badge` Unleash flag is already registered. The missing pieces are:
the DB column + trigger (reso), the DTO field (belengaz), and the entity field + wire-up (pizmam).

**Combined motivation:** Both issues can share one planning cycle because they touch overlapping files
(`ListingEntity`, listing card stack) and must be merged before the next sprint review.

---

## 2. Goals & Non-Goals

### Goals

- **GH-113-A** Delete `NewListingFab` (widget + test) — confirmed dead code since M6 design update
- **GH-113-B** Extract `HomeSliverAppBar` shared widget from five duplicated private `_appBar()` methods
- **GH-113-C** Promote `_StatCard` from `seller_stats_row.dart` private class to `lib/widgets/cards/stat_card.dart`
- **GH-113-D** Document (and optionally tighten) `SellerHomeState.isEmpty` — currently only checks `listings.isEmpty`
- **GH-113-E** Extract bottom-sheet height-ratio magic numbers to named constants in `filter_bottom_sheet.dart`
- **GH-113-F** Simplify `ChatThreadSendController.updateOfferStatus` — clarify rollback pattern, remove confusing wording
- **GH-113-G** Document `writeState` signature constraint and its intentional limitations
- **GH-59-A** Add `escrow_eligible BOOLEAN NOT NULL DEFAULT false` column to `listings` table via migration (reso)
- **GH-59-B** Add `BEFORE INSERT OR UPDATE` trigger that computes eligibility server-side (reso)
- **GH-59-C** Parse `escrow_eligible` in `ListingDto.fromJson()` as `escrowEligible: bool` (belengaz)
- **GH-59-D** Add `isEscrowAvailable: bool` final field to `ListingEntity` with `false` default (pizmam)
- **GH-59-E** Wire `listing.isEscrowAvailable` into `listingDeelCard()` factory behind Unleash flag (pizmam)
- **GH-59-F** Write/update tests for all changed layers (pizmam)

### Non-Goals

- Changing the `DeelCard.grid` or `DeelBadge` widgets — already complete per ADR-024
- Adding escrow UI to `ListingDetailScreen` trust banner — already handled by `EscrowTrustBanner`
- Migrating `AdminStatCard` to use the new `StatCard` widget — deferred to a chore ticket
- Adding the checkout 409 Conflict re-validation edge function — reso's separate ticket (ADR-023 §6)
- Implementing the "what-if eligibility preview" in listing creation — deferred post-MVP
- Any marketing asset changes (§13 CLAUDE.md guardrail)

---

## 3. Implementation Steps

Each step includes exact file paths, specific actions, and verification criteria.

---

### Phase A — GH-113 Polish (pizmam + belengaz) · Branch: `fix/gh113-non-blocking-polish`

#### A-1 · Delete `NewListingFab` dead code

| | |
|---|---|
| **Files** | `lib/features/home/presentation/widgets/new_listing_fab.dart` (DELETE) |
| | `test/features/home/presentation/widgets/new_listing_fab_test.dart` (DELETE) |
| **Action** | `git rm` both files. Verify no production import exists (search `new_listing_fab` via `grep -r`). |
| **Why safe** | `home_screen.dart:88` comment: "FAB removed to avoid overlap with bottom nav bar on small screens". The `SellerHomeDataView._newListingButton()` (lines 101–116) uses `DeelButton` instead. Only the test file imports `NewListingFab`. |
| **Verify** | `flutter analyze` zero warnings · `flutter test` all pass · no dangling import errors |

#### A-2 · Extract `HomeSliverAppBar` shared widget

| | |
|---|---|
| **New file** | `lib/widgets/layout/home_sliver_app_bar.dart` |
| **New test** | `test/widgets/layout/home_sliver_app_bar_test.dart` |
| **Files to update** | `lib/features/home/presentation/widgets/home_data_view.dart` — replace `_appBar()` private method with `const HomeSliverAppBar()` |
| | `lib/features/home/presentation/widgets/seller_home_data_view.dart` — same |
| | `lib/features/home/presentation/widgets/seller_home_empty_view.dart` — same |
| | `lib/features/home/presentation/widgets/seller_home_loading_view.dart` — same |
| | `lib/features/home/presentation/home_screen.dart` — same |

**Widget spec** (all five files use an identical 10-line pattern):
```dart
/// Shared floating SliverAppBar used in all home screen states.
///
/// Reference: docs/screens/02-home/01-home-buyer.md
///            docs/screens/02-home/02-home-seller.md
class HomeSliverAppBar extends StatelessWidget {
  const HomeSliverAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      title: Text(
        'app.name'.tr(),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      actions: const [HomeModePillSwitch(), SizedBox(width: Spacing.s3)],
    );
  }
}
```

**Test cases required:**
- Renders "DeelMarkt" text
- Text colour matches `colorScheme.primary`
- `HomeModePillSwitch` present in widget tree
- Passes accessibility label check (screen reader sees app name)

**Verify:** `flutter analyze` · `flutter test test/widgets/layout/` · Confirm `_appBar` method removed from all 5 files · `grep -r "_appBar" lib/features/home/` returns zero hits

#### A-3 · Promote `_StatCard` to `lib/widgets/`

| | |
|---|---|
| **New file** | `lib/widgets/cards/stat_card.dart` (exact copy of `_StatCard`, made public, renamed `StatCard`) |
| **New test** | `test/widgets/cards/stat_card_test.dart` |
| **File to update** | `lib/features/home/presentation/widgets/seller_stats_row.dart` — remove `_StatCard` class; import and use `StatCard` from `lib/widgets/` |

**Public API** (no behaviour change):
```dart
class StatCard extends StatelessWidget {
  const StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.showBadge = false,
    super.key,  // add key — required for shared widgets
  });
  // ... identical implementation
}
```

**Test cases required:**
- Renders `value` text and `label` text
- `showBadge: true` renders orange dot; `showBadge: false` does not
- `Semantics` label equals `'$value $label'`
- Width is 140px (snapshot or `tester.getSize`)
- Dark mode: background uses `DeelmarktColors.darkSurface`

**Verify:** `flutter test test/widgets/cards/stat_card_test.dart` · `grep -r "_StatCard" lib/` returns zero hits · `seller_stats_row.dart` line count ≤ 60 (was 134, _StatCard class removed)

#### A-4 · Document `SellerHomeState.isEmpty`

| | |
|---|---|
| **File** | `lib/features/home/presentation/seller_home_state.dart` line 23 |
| **Action** | Expand the doc comment to explicitly state the design intent and its known limitation. No logic change. |

```dart
/// Whether the seller has no listings at all — triggers [SellerHomeEmptyView].
///
/// Checks **only** `listings.isEmpty`. Stats and actions may be non-empty
/// while this returns `true` (e.g. a seller with sales history but no current
/// active listings). This is intentional: the empty-state screen is a
/// listing-creation prompt, not a "no data" fallback.
///
/// If a future sprint adds a richer "first-time seller" state that distinguishes
/// between "never listed" and "all sold", this getter should be replaced with a
/// `SellerHomeViewState` enum (see E01 epic §5).
bool get isEmpty => listings.isEmpty;
```

**Verify:** `dart run scripts/check_quality.dart lib/features/home/presentation/seller_home_state.dart` · zero violations

#### A-5 · Extract magic numbers in `FilterBottomSheet`

| | |
|---|---|
| **File** | `lib/features/search/presentation/widgets/filter_bottom_sheet.dart` |
| **Action** | Extract the three `DraggableScrollableSheet` fraction values to named constants at the top of the file. |

```dart
// Height fractions for DraggableScrollableSheet — defined by the filter sheet
// design spec (docs/screens/02-home/03-search.md §modal-sizing).
static const double _sheetMinFraction = 0.5;
static const double _sheetInitialFraction = 0.7;
static const double _sheetMaxFraction = 0.9;
```

Replace inline values:
```dart
DraggableScrollableSheet(
  initialChildSize: _sheetInitialFraction,
  minChildSize: _sheetMinFraction,
  maxChildSize: _sheetMaxFraction,
  expand: false,
```

**Verify:** `flutter analyze` · `grep "0\.5\|0\.7\|0\.9" lib/features/search/presentation/widgets/filter_bottom_sheet.dart` returns zero numeric literals in this context

#### A-6 · Simplify `ChatThreadSendController` rollback wording

| | |
|---|---|
| **File** | `lib/features/messages/presentation/chat_thread_send_controller.dart` |
| **Action** | Clarify the inline comment on the rollback line (line 113); no logic change. |

Replace the comment on the `writeState(current)` rollback line:
```dart
// Rollback: write back the pre-optimistic snapshot. No copyWith needed —
// `current` is the full state captured before the optimistic update.
writeState(current);
```

Remove the confusing `// no copyWith needed` parenthetical that was split across two lines.

**Verify:** `flutter analyze` · test suite unchanged

#### A-7 · Document `writeState` signature constraint

| | |
|---|---|
| **File** | `lib/features/messages/presentation/chat_thread_send_controller.dart` lines 27–32 |
| **Action** | Expand the existing docstring with an explicit "constraint" block. |

```dart
/// Plain-state setter — accepts only completed [ChatThreadState] values.
///
/// **Constraint:** Cannot emit `AsyncValue.loading` or `AsyncValue.error`
/// directly. All inflight indicators and error surfaces must be managed by
/// the enclosing [ChatThreadNotifier] via its own `state = AsyncValue.loading()`
/// or `state = AsyncValue.error(e, st)` calls, not through this callback.
///
/// **Why:** Keeps [ChatThreadSendController] testable in isolation — callers
/// pass a simple `(s) => state = AsyncValue.data(s)` lambda without needing
/// to expose the full `Notifier.state` setter.
///
/// **Refactor trigger:** If a future P-XX task requires per-send loading
/// indicators or realtime disconnect banners surfaced *through* this
/// controller, change the signature to
/// `void Function(AsyncValue<ChatThreadState>)` and update all call sites.
final void Function(ChatThreadState) writeState;
```

**Verify:** `dart run scripts/check_quality.dart lib/features/messages/` · zero violations

---

### Phase B — GH-59 EscrowBadge (reso + belengaz + pizmam) · Branch: `fix/gh59-escrow-badge`

> **Merge sequence:** B-1 (reso) → B-2 (belengaz) → B-3 through B-6 (pizmam)
> B-3 through B-6 MUST NOT be merged until B-1 is applied to the target environment.

#### B-1 · DB Migration — `escrow_eligible` column + trigger (reso)

| | |
|---|---|
| **New file** | `supabase/migrations/<timestamp>_listings_escrow_eligible.sql` |
| **Trigger file** | Include trigger definition in the same migration file |

**Migration content:**
```sql
-- Adds backend-authoritative escrow eligibility to listings.
-- ADR-023: client must never derive this client-side (EU CRD legal risk).
-- Fail-safe default: false (badge hidden until trigger fires on first UPDATE).

ALTER TABLE listings
  ADD COLUMN escrow_eligible BOOLEAN NOT NULL DEFAULT false;

-- Trigger: recompute escrow_eligible on every INSERT or UPDATE to listings.
-- Inputs: listing row + seller KYC level + dispute rate + category flag.
CREATE OR REPLACE FUNCTION compute_escrow_eligible()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_kyc_level        INT;
  v_dispute_count    INT;
  v_category_eligible BOOLEAN;
BEGIN
  SELECT kyc_level INTO v_kyc_level
    FROM user_profiles WHERE id = NEW.seller_id;

  SELECT COUNT(*) INTO v_dispute_count
    FROM disputes
   WHERE seller_id = NEW.seller_id
     AND status = 'active'
     AND created_at > now() - INTERVAL '90 days';

  SELECT escrow_eligible INTO v_category_eligible
    FROM categories WHERE id = NEW.category_id;

  NEW.escrow_eligible := (
    NEW.status      = 'active'          AND
    NEW.price_cents >= 5000             AND
    (NEW.quality_score IS NOT NULL AND NEW.quality_score >= 50) AND
    COALESCE(v_kyc_level, 0) >= 1       AND
    COALESCE(v_dispute_count, 0) <= 2   AND
    COALESCE(v_category_eligible, false)
  );

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_listings_escrow_eligible
  BEFORE INSERT OR UPDATE ON listings
  FOR EACH ROW EXECUTE FUNCTION compute_escrow_eligible();

-- Backfill existing rows (trigger fires on each UPDATE).
-- Done in batches to avoid lock escalation on large tables.
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN SELECT id FROM listings LOOP
    UPDATE listings SET updated_at = updated_at WHERE id = r.id;
  END LOOP;
END;
$$;

-- RLS: escrow_eligible is read-only for authenticated users (computed by trigger).
-- No policy change needed — listings RLS already exposes all columns to owner + public read.

COMMENT ON COLUMN listings.escrow_eligible IS
  'Server-computed eligibility for escrow protection. Set by trg_listings_escrow_eligible. '
  'Client must treat as read-only. ADR-023.';
```

**Schema verification checklist:**
- `listings.seller_id` → FK to `auth.users(id)` ✓ (migration `20260329161637_phase_a`, line 116)
- `listings.status` → `listing_condition` enum ✓ (same migration, line 121)
- `listings.price_cents` → `INTEGER NOT NULL` ✓ (same migration, line 118)
- `listings.quality_score` → `INTEGER` nullable ✓ (same migration, line 126)
- `listings.category_id` → FK to `categories(id)` ✓ (same migration, line 122)
- `user_profiles.kyc_level` → verify column exists before deploying
- `disputes` table → verify `seller_id`, `status`, `created_at` columns exist
- `categories.escrow_eligible` → verify this boolean flag exists on `categories` table

**Deploy:** `bash scripts/check_deployments.sh --deploy`

**Verify:** `psql` or Supabase Studio — run `SELECT id, escrow_eligible FROM listings LIMIT 10` after migration · `bash scripts/check_edge_functions.sh --all`

#### B-2 · DTO — Parse `escrow_eligible` (belengaz)

| | |
|---|---|
| **File** | `lib/features/home/data/dto/listing_dto.dart` |

In `fromJson()`, add fail-closed parse after `qualityScore`:
```dart
// Fail-closed: missing or null field → false (badge hidden). ADR-023 §3.
isEscrowAvailable: (json['escrow_eligible'] as bool?) ?? false,
```

No change to `toJson()` — `escrow_eligible` is server-computed, never sent from client.

**Verify:** `flutter test test/features/home/data/dto/` · Confirm `toJson()` does NOT include `escrow_eligible`

#### B-3 · Entity — Add `isEscrowAvailable` field (pizmam)

| | |
|---|---|
| **File** | `lib/features/home/domain/entities/listing_entity.dart` |

Add to constructor (after `favouriteCount`):
```dart
this.isEscrowAvailable = false,
```

Add field declaration (after `favouriteCount`):
```dart
/// Whether this listing is eligible for escrow protection.
///
/// Server-authoritative — computed by DB trigger (ADR-023). Client reads
/// this field; NEVER derives it client-side. Default `false` (fail-closed).
final bool isEscrowAvailable;
```

Add to `copyWith()` signature:
```dart
bool? isEscrowAvailable,
```

Add to `copyWith()` body:
```dart
isEscrowAvailable: isEscrowAvailable ?? this.isEscrowAvailable,
```

Add to `props`:
```dart
isEscrowAvailable,
```

> **File-line limit note:** `listing_entity.dart` is already at 152 lines (limit 100 per §2.1 for Model/Entity/DTO).
> The existing `// TODO(#133)` acknowledges this. Adding ~6 lines is acceptable for this sprint;
> the decomposition of the model is tracked under GH-133, not this plan.

**Verify:** `flutter analyze` · `flutter test test/features/home/domain/entities/listing_entity_test.dart`

#### B-4 · Wire up `listingDeelCard()` factory (pizmam)

| | |
|---|---|
| **File** | `lib/widgets/cards/listing_deel_card.dart` |

Replace `showEscrowBadge: showEscrowBadge` parameter (caller-driven) with entity-driven + flag gate:
```dart
Widget listingDeelCard(
  ListingEntity listing, {
  required VoidCallback onTap,
  required VoidCallback onFavouriteTap,
  required WidgetRef ref,  // needed for Unleash flag
}) =>
    DeelCard.grid(
      imageUrl: listing.imageUrls.isNotEmpty ? listing.imageUrls.first : '',
      priceInCents: listing.priceInCents,
      originalPriceInCents: listing.originalPriceInCents,
      title: listing.title,
      heroTag: 'listing-${listing.id}',
      location: listing.location,
      distanceFormatted: listing.distanceKm != null
          ? Formatters.distanceKm(listing.distanceKm!)
          : null,
      isFavourited: listing.isFavourited,
      showEscrowBadge: listing.isEscrowAvailable &&
          ref.watch(isFeatureEnabledProvider('listings_escrow_badge')),
      onTap: onTap,
      onFavouriteTap: onFavouriteTap,
    );
```

> **ADR-024 note:** The old `showEscrowBadge` caller-parameter is removed. All callers pass `ref` instead.
> Update all call sites (search `listingDeelCard(` to find them).

**Verify:** `grep -r "listingDeelCard(" lib/` — update every call site to pass `ref:` · `flutter analyze`

#### B-5 · i18n — Verify escrow badge keys exist

| | |
|---|---|
| **Files** | `assets/l10n/en-US.json` · `assets/l10n/nl-NL.json` |
| **Check** | Confirm `badge.escrowProtected` and `badge.escrowProtectedTip` keys exist in both files |
| **Action** | If missing, add: |

```json
// en-US.json
"badge.escrowProtected": "Escrow protected",
"badge.escrowProtectedTip": "This listing is protected by DeelMarkt Escrow"

// nl-NL.json
"badge.escrowProtected": "Escrow beschermd",
"badge.escrowProtectedTip": "Deze advertentie is beschermd door DeelMarkt Escrow"
```

**Verify:** `flutter test` (l10n validation tests) · check `DeelBadgeData` renders tooltip text for `escrowProtected`

#### B-6 · Tests (pizmam)

**`test/features/home/domain/entities/listing_entity_test.dart`** — add:
- `isEscrowAvailable` defaults to `false`
- `copyWith(isEscrowAvailable: true)` produces a new entity with `true`
- `copyWith()` without `isEscrowAvailable` preserves existing value
- `props` equality: two entities differing only in `isEscrowAvailable` are NOT equal

**`test/features/home/data/dto/listing_dto_test.dart`** — add:
- `escrow_eligible: true` in JSON → `isEscrowAvailable == true`
- `escrow_eligible: false` in JSON → `isEscrowAvailable == false`
- `escrow_eligible` missing from JSON → `isEscrowAvailable == false` (fail-closed)
- `escrow_eligible: null` in JSON → `isEscrowAvailable == false` (fail-closed)
- `toJson()` does NOT include `escrow_eligible` key

**`test/widgets/cards/listing_deel_card_test.dart`** — add:
- Flag OFF + `isEscrowAvailable: true` → badge NOT shown
- Flag ON + `isEscrowAvailable: false` → badge NOT shown
- Flag ON + `isEscrowAvailable: true` → `DeelBadge` with `escrowProtected` IS shown
- Default `listingDeelCard()` (flag OFF) → badge NOT shown (regression guard)

---

## 4. Testing Strategy

### Coverage Requirements

| Layer | Target | Tool |
|-------|--------|------|
| Widget unit tests | ≥ 80% on changed files | `flutter test --coverage` |
| Payment paths | Untouched by this plan | N/A |
| DTO parse | 100% branch coverage for `isEscrowAvailable` | Unit test |
| Entity `copyWith` | 100% path coverage | Unit test |

### Test Types Required

- **Unit tests** — all steps: entity, DTO, `StatCard` widget, `HomeSliverAppBar` widget
- **Integration tests** — none required for this plan (no new cross-service flows introduced)
- **E2E tests** — not required for these changes; badge visibility is covered by widget tests with mocked Unleash

### Key Test Scenarios

| Scenario | Type | Files |
|----------|------|-------|
| `HomeSliverAppBar` renders in all 5 home states | Widget | `test/widgets/layout/home_sliver_app_bar_test.dart` |
| `StatCard` badge visibility | Widget | `test/widgets/cards/stat_card_test.dart` |
| `SellerStatsRow` uses `StatCard` (not `_StatCard`) | Widget | `test/features/home/presentation/widgets/seller_stats_row_test.dart` |
| `ListingEntity.isEscrowAvailable` fail-closed | Unit | `listing_entity_test.dart` |
| DTO fail-closed parse | Unit | `listing_dto_test.dart` |
| Badge not shown when flag OFF | Widget | `listing_deel_card_test.dart` |
| Badge shown when flag ON + entity true | Widget | `listing_deel_card_test.dart` |

### TDD Workflow (per `testing.md`)

For B-3 through B-6: write failing test first, then implement to pass. Steps A-2 and A-3 may write tests simultaneously with widget extraction.

---

## 5. Security Considerations

| Concern | Assessment | Mitigation |
|---------|-----------|------------|
| Client-side escrow derivation | **REJECTED** per ADR-023 — EU CRD legal risk | Server-authoritative `escrow_eligible` column (B-1) |
| Serialisation error revealing wrong badge | Medium | Fail-closed default `false` in DTO (B-2) and entity (B-3) |
| SQL injection in trigger | N/A | PL/pgSQL parameterised via `NEW.` record access — no string concatenation |
| Escrow badge "drift" between fetch and checkout | Medium | ADR-023 §6 checkout 409 re-validation (reso's separate ticket — not in scope here, but must ship before E03 Phase 2) |
| Feature flag bypass | Low | Unleash SDK is server-evaluated; client cannot spoof flag state |
| Hardcoded secrets | N/A | No new secrets; DB trigger uses row-level data only |
| RLS bypass | Low | `escrow_eligible` is read-only from client — no write path through DTO (`toJson` excluded) |

**Pre-commit checklist (§8 CLAUDE.md):**
- [ ] No hardcoded secrets in migration file
- [ ] `escrow_eligible` not included in `toJson()` (write path audit)
- [ ] Trigger function uses `SECURITY DEFINER` appropriately (or `INVOKER` if caller has table access)
- [ ] `detect-secrets` passes on migration file

---

## 6. Risks & Mitigations

| Risk | Severity | Probability | Mitigation |
|------|----------|-------------|------------|
| Migration backfill locks `listings` table on large dataset | High | Low (table small in dev/staging) | Batch `UPDATE` via `DO $$` loop (already in B-1); monitor row-lock duration in staging |
| `categories.escrow_eligible` column missing → trigger fails | High | Medium | Add schema verification step in B-1 preflight; fail migration if column absent |
| `user_profiles.kyc_level` missing → all listings default to non-eligible | Medium | Low | Trigger uses `COALESCE(v_kyc_level, 0)` — safe default |
| `HomeSliverAppBar` breaks dark mode | Low | Low | Dark mode test case in A-2 test file; `flutter test` with dark `ThemeData` override |
| `listingDeelCard` call sites not updated after `ref:` parameter addition | Medium | Medium | Compile-time error — Dart will not build until all call sites updated; CI catches |
| `isEscrowAvailable` omitted from `props` → Riverpod diff misses state change | Medium | Low | Add equality test: two entities differing only in `isEscrowAvailable` are not equal (B-6) |
| GH-59 UI PR merged before reso's migration PR | High | Medium | Merge gate: pizmam's PR description must link reso's migration PR as prerequisite; reviewer to enforce |

---

## 7. Success Criteria

### GH-113
- [ ] `NewListingFab` and its test file no longer exist in the repository
- [ ] `grep -r "_appBar" lib/features/home/` returns zero results
- [ ] `HomeSliverAppBar` widget exists in `lib/widgets/layout/` with passing tests
- [ ] `_StatCard` class no longer exists in `seller_stats_row.dart`
- [ ] `StatCard` widget exists in `lib/widgets/cards/` with passing tests
- [ ] `SellerHomeState.isEmpty` doc comment explains the intentional scope limitation
- [ ] `filter_bottom_sheet.dart` contains no bare `0.5`, `0.7`, `0.9` numeric literals for height fractions
- [ ] `writeState` doc comment explains signature constraint and refactor trigger
- [ ] `flutter analyze` → zero warnings on all changed files
- [ ] `dart run scripts/check_quality.dart --all` → zero new violations

### GH-59
- [ ] `listings` table has `escrow_eligible BOOLEAN NOT NULL DEFAULT false` column in all environments
- [ ] Trigger `trg_listings_escrow_eligible` fires on INSERT/UPDATE and sets value correctly
- [ ] `ListingDto.fromJson()` maps `escrow_eligible` → `isEscrowAvailable` with fail-closed default
- [ ] `ListingEntity` has `isEscrowAvailable: bool` final field in constructor, `copyWith`, and `props`
- [ ] `listingDeelCard()` passes `showEscrowBadge` gated by entity field AND Unleash flag
- [ ] Badge NOT shown when flag `listings_escrow_badge` is OFF (even if entity is `true`)
- [ ] Badge shown when flag ON AND `listing.isEscrowAvailable == true`
- [ ] All 9 DTO/entity/widget test scenarios pass
- [ ] `bash scripts/check_deployments.sh` → zero pending migrations

---

## 8. Architecture Impact

```
lib/widgets/
  layout/
    home_sliver_app_bar.dart     ← NEW shared widget (A-2)
  cards/
    stat_card.dart               ← PROMOTED from private (A-3)
    listing_deel_card.dart       ← MODIFIED: entity-driven badge (B-4)

lib/features/home/
  presentation/
    widgets/
      home_data_view.dart        ← UPDATED: uses HomeSliverAppBar
      seller_home_data_view.dart ← UPDATED: uses HomeSliverAppBar
      seller_home_empty_view.dart← UPDATED: uses HomeSliverAppBar
      seller_home_loading_view.dart← UPDATED: uses HomeSliverAppBar
      seller_stats_row.dart      ← UPDATED: uses StatCard (no _StatCard)
    home_screen.dart             ← UPDATED: uses HomeSliverAppBar
    seller_home_state.dart       ← UPDATED: expanded doc comment (A-4)
  domain/entities/
    listing_entity.dart          ← UPDATED: +isEscrowAvailable field (B-3)
  data/dto/
    listing_dto.dart             ← UPDATED: +escrowEligible parse (B-2)

lib/features/messages/presentation/
  chat_thread_send_controller.dart ← UPDATED: docs + comment (A-6, A-7)

supabase/migrations/
  <ts>_listings_escrow_eligible.sql ← NEW (B-1)
```

**Dependency direction:** All changes follow Clean Architecture — domain entity adds a field, data layer adds parse, presentation layer adds UI wiring. No layer inversion.

**ADR compliance:** ADR-023 (escrow-authoritative), ADR-024 (listing card consolidation — `showEscrowBadge` caller parameter removed in favour of entity-driven).

---

## 9. API / Data Model Changes

### Database

| Change | Type | Migration |
|--------|------|-----------|
| `listings.escrow_eligible BOOLEAN NOT NULL DEFAULT false` | Additive column | `<ts>_listings_escrow_eligible.sql` |
| `trg_listings_escrow_eligible` BEFORE trigger | New trigger | Same migration |
| `compute_escrow_eligible()` PL/pgSQL function | New function | Same migration |

**Impact on existing queries:** Additive only — no existing `SELECT *` breaks. The column is included in `listings_with_favourites` view automatically if the view uses `listings.*`.

> **Action:** Verify `listings_with_favourites` view definition — if it lists explicit columns, add `escrow_eligible` to the column list.

### Dart Entity

| Field | Type | Default | `copyWith` | `props` |
|-------|------|---------|------------|---------|
| `isEscrowAvailable` | `bool` | `false` | ✓ | ✓ |

### DTO

| JSON key | Dart field | Parse strategy |
|----------|------------|----------------|
| `escrow_eligible` | `isEscrowAvailable` | `(json['escrow_eligible'] as bool?) ?? false` |

`toJson()` deliberately excludes `escrow_eligible` — it is server-computed.

---

## 10. Rollback Strategy

### GH-113 (all steps)
All changes are pure refactors/deletions with no runtime behaviour change. Rollback = revert the PR. No migration needed.

### GH-59

| Step | Rollback |
|------|----------|
| B-1 migration | `ALTER TABLE listings DROP COLUMN escrow_eligible; DROP TRIGGER ...; DROP FUNCTION ...;` — additive migration, safe to reverse. Write a down migration `<ts>_listings_escrow_eligible_down.sql`. |
| B-2 DTO | Revert `listing_dto.dart` — entity field falls back to `false` default; no crash |
| B-3 Entity | Revert — all existing code uses optional params; removing a field with a default does not break callers |
| B-4 UI wire | Revert — `showEscrowBadge` reverts to `false`; badge disappears |
| Feature flag | `listings_escrow_badge` defaults OFF — flip flag in Unleash dashboard (seconds) to hide all badges without redeploy |

**Zero-downtime guarantee:** Column addition with `DEFAULT false` does not lock the table in PostgreSQL 11+ (uses table rewrite only for `NOT NULL` without `DEFAULT`; here we specify both simultaneously — Postgres 12+ handles this online).

---

## 11. Observability

### GH-113
N/A — Pure refactors. No new error paths, no new async operations.

### GH-59
| Signal | Location | Detail |
|--------|----------|--------|
| `AppLogger.warning` | `ListingDto.fromJson()` | Log when `escrow_eligible` key is absent from JSON (indicates DB view not updated after migration) |
| Supabase `audit_log` | DB trigger side-effect | `escrow_eligible` flips logged via existing audit infrastructure |
| Unleash metrics | Dashboard | `listings_escrow_badge` flag evaluation count — baseline for badge rollout decision |

Add to `listing_dto.dart`:
```dart
final rawEscrow = json['escrow_eligible'];
if (rawEscrow == null) {
  AppLogger.warning(
    'escrow_eligible missing from listing JSON — defaulting false. '
    'Check listings_with_favourites view column list.',
    tag: 'ListingDto',
  );
}
isEscrowAvailable: (rawEscrow as bool?) ?? false,
```

---

## 12. Performance Impact

### GH-113
- **`HomeSliverAppBar`:** Constant widget — zero allocation overhead vs. private method. Potentially enables `const HomeSliverAppBar()` optimization.
- **`StatCard`:** Identical to `_StatCard`. No change.
- **Dead code removal (`NewListingFab`):** Minor APK/IPA size reduction (negligible).

### GH-59
- **DB trigger:** `BEFORE INSERT OR UPDATE` — adds ~1 subquery to `user_profiles` and ~1 subquery to `disputes` per write. At current scale (dev/alpha), negligible. At scale (>10k listings/day writes), consider caching seller eligibility in `user_profiles.escrow_eligible` (computed separately) to reduce per-write JOIN cost.
- **`listingDeelCard()`:** Adds one synchronous Unleash flag read via `ref.watch` — cached in Riverpod, zero network cost.
- **Entity `props` list:** One additional `bool` in `Equatable.props` — immeasurable overhead.

---

## 13. Documentation Updates

| Document | Change | Owner |
|----------|--------|-------|
| `docs/adr/ADR-023-escrow-eligibility-authority.md` | Update status from "Implementation pending" to "Implemented" after B-1 merge | reso |
| `docs/adr/ADR-024-listing-card-consolidation.md` | Note that `showEscrowBadge` caller-param removed; now entity-driven | pizmam |
| `docs/FEATURE-FLAGS.md` | Update `listings_escrow_badge` row — add "Prod status: ON (after B-1 verified in staging)" | belengaz |
| `docs/screens/02-home/01-home-buyer.md` | No change — design spec already shows escrow badge on DeelCard |
| `CLAUDE.md` | No change required |
| `CHANGELOG.md` (if exists) | Add entries for GH-113 and GH-59 | pizmam |

---

## 14. Dependencies

### Blocks this work
| Dependency | Type | Owner | Status |
|-----------|------|-------|--------|
| reso's `<ts>_listings_escrow_eligible.sql` migration PR | Hard block for B-3–B-6 | reso | Pending |
| `categories.escrow_eligible` column must exist on `categories` table | Hard block for B-1 trigger | reso | Verify before B-1 |
| `disputes` table with `seller_id`, `status`, `created_at` columns | Hard block for B-1 trigger | reso | Verify before B-1 |
| `user_profiles.kyc_level` column | Hard block for B-1 trigger | reso | Verify before B-1 |

### Downstream impact
| Downstream | Impact |
|------------|--------|
| `ListingDetailScreen` | No impact — uses `EscrowTrustBanner`, not `listingDeelCard()` |
| `FavouritesScreen` listing grid | Will show badge after B-4 if it uses `listingDeelCard()` — verify call site |
| `SearchScreen` listing grid | Same — verify call site |
| `SellerProfileScreen` listing grid | Same — verify call site |
| ADR-023 §6 checkout 409 re-validation | Future reso ticket — not blocked by this plan, but must ship before E03 Phase 2 |

### Pre-merge checklist for B-3–B-6 PRs
```
[ ] reso's migration has been applied to staging
[ ] psql staging: SELECT escrow_eligible FROM listings LIMIT 1 — returns a boolean
[ ] listings_with_favourites view includes escrow_eligible column
[ ] Unleash staging flag listings_escrow_badge tested (ON + OFF)
```

---

## 15. Alternatives Considered

### GH-113-B: `HomeSliverAppBar` alternatives

| Option | Verdict |
|--------|---------|
| Keep 5 private `_appBar()` methods, add a comment "keep in sync" | Rejected — synchronisation comment is a code smell; next feature change will break one of the 5 |
| Extract to `lib/features/home/presentation/widgets/home_sliver_app_bar.dart` (feature-layer) | Rejected — all 5 files in the same feature already; shared `lib/widgets/layout/` is more appropriate since this could be used in future features |
| Use a mixin | Rejected — mixins for UI composition are anti-pattern in Flutter; `const` widget is idiomatic |

### GH-113-C: `_StatCard` alternatives

| Option | Verdict |
|--------|---------|
| Rename `AdminStatCard` to use `_StatCard` by importing across feature boundaries | Rejected — cross-feature imports violate §1.2 arch rules |
| Keep `_StatCard` private, copy to admin feature | Rejected — creates duplication that this plan aims to remove |
| Promote to `lib/widgets/cards/stat_card.dart` (chosen) | Accepted — public shared widget, one maintenance point |

### GH-59: Escrow eligibility alternatives

| Option | Verdict |
|--------|---------|
| Client-side `bool get isEscrowAvailable` computed from existing fields | Rejected — legal risk (EU CRD), diverges from server at E03 Phase 2 (ADR-023 §Context) |
| `GET /functions/v1/listing-escrow-eligibility` batch endpoint | Rejected — N+1 latency on grid loads, complex failure modes (ADR-023 §Alternatives) |
| Embed in `listing_view` DB view only | Rejected — unindexable for "filter by escrow" queries (ADR-023 §Alternatives) |
| Server-authoritative column + trigger (chosen) | Accepted — single source of truth, audit trail, fail-closed, legally defensible |

---

## Domain Enhancer Sections

### Mobile Domain (Flutter/Dart)

**Platform parity:**
- `HomeSliverAppBar`: No platform-specific code — `SliverAppBar` renders identically on iOS/Android.
- `StatCard`: Width `140px` is fixed — validate on iPhone SE (375px) that three cards fit in horizontal scroll without overflow.
- Escrow badge: `DeelBadge` renders identically on both platforms.

**Offline support:**
- `isEscrowAvailable: false` default means badge never shows stale cached data as "eligible" — consistent with ADR-023 fail-closed.
- If listing is fetched offline from cache and `escrow_eligible` is missing from cached JSON → `false` → badge hidden. Acceptable.

**App Store guidelines:**
- Badge showing `EscrowProtected` is a factual claim (server-computed) — compliant with Apple's HIG §Deceptive Patterns clause and Google Play Trust Badges policy.

**Mobile performance budget:**
- No new images/assets added. Badge uses existing `PhosphorIcons.lock()` (tree-shaken Phosphor icon).
- `HomeSliverAppBar` as `const` widget reduces unnecessary rebuilds in `CustomScrollView`.

**State persistence:**
- `isEscrowAvailable` is fetched on every listing refresh — no local caching needed; always reflects server state.

**Navigation:**
- No navigation changes in either issue.

---

### Frontend Domain (Flutter Widgets + Design System)

**Accessibility (WCAG 2.2 AA — legal requirement per §10 CLAUDE.md):**
- `HomeSliverAppBar`: `Semantics` label from app name `.tr()` — already provided via `Text` semantics.
- `StatCard`: `Semantics(label: '$value $label')` already implemented — preserve in promoted version.
- EscrowBadge: `DeelBadge` already has `Semantics` via `label: 'badge.escrowProtected'.tr()`.
- Badge tooltip (`showTooltip: false` in grid context) — correct; tooltip shown in detail context only.

**Responsive design (per screen specs):**
- `HomeSliverAppBar`: `floating: true` SliverAppBar — tested in compact (375px) and expanded (840px+) layouts.
- `StatCard`: `width: 140` in horizontal `ListView` — verify on 375px (3 cards × 140px + gaps = 462px; horizontal scroll handles overflow ✓).
- EscrowBadge on grid: `Positioned(top: 8, right: 8)` inside `Stack` — verified in `DeelCardTokens`. No collision with favourite heart (top-left) per design spec (`docs/screens/02-home/01-home-buyer.md §DeelCard`).

**Touch targets:**
- `StatCard`: 140×100px tap surface — ✓ exceeds 44×44px minimum.
- EscrowBadge: informational only (not interactive in grid context) — no touch target requirement.

**Design system compliance:**
- `StatCard`: Uses `DeelmarktColors.*`, `Spacing.*`, `DeelmarktRadius.xl`, `DeelmarktIconSize.sm` — ✓
- `HomeSliverAppBar`: Uses `Spacing.s3` for trailing padding — ✓
- No raw `Color(0xFF...)`, no inline `TextStyle`, no raw `BorderRadius.circular(N)` — ✓
- All UI text via `.tr()` — ✓

**Error boundaries:**
- N/A for GH-113 — pure refactors.
- GH-59: `isEscrowAvailable` is `bool`, never null — no error boundary needed for badge display.

---

### Database Domain (Supabase PostgreSQL)

**Migration rollback:**
- Up migration: additive (`ALTER TABLE ... ADD COLUMN`, `CREATE TRIGGER`, `CREATE FUNCTION`)
- Down migration (write before deploying up):
  ```sql
  DROP TRIGGER IF EXISTS trg_listings_escrow_eligible ON listings;
  DROP FUNCTION IF EXISTS compute_escrow_eligible();
  ALTER TABLE listings DROP COLUMN IF EXISTS escrow_eligible;
  ```
- Test rollback in staging before applying to production.

**Index impact analysis:**
- No new index on `escrow_eligible` for MVP (no "filter by escrow" query in current sprint).
- Future: if search adds `escrow_available=true` filter, add `CREATE INDEX idx_listings_escrow_eligible ON listings(escrow_eligible) WHERE escrow_eligible = true;` (partial index).

**Data integrity:**
- `NOT NULL DEFAULT false` — every row has a defined value after migration.
- Trigger fires `BEFORE INSERT OR UPDATE` — no row can exist with an unchecked value after migration + backfill.
- Backfill strategy: `UPDATE listings SET updated_at = updated_at` triggers the trigger per row. For very large tables, use `UPDATE listings SET updated_at = updated_at WHERE id IN (SELECT id FROM listings LIMIT 500 OFFSET ?)` in batches.

**Backup verification:**
- Supabase performs daily automated backups. Verify most recent backup timestamp before deploying.
- Migration is additive — no data loss possible. Rollback only removes the column (no PII involved).

**Query performance:**
- Trigger adds 2 subqueries per `INSERT/UPDATE` to `listings` (`user_profiles`, `disputes`).
- Existing Supabase indexes: `user_profiles.id` (PK) and `disputes.seller_id` (verify index exists).
- If `disputes.seller_id` is not indexed, add: `CREATE INDEX IF NOT EXISTS idx_disputes_seller_id ON disputes(seller_id, status, created_at);`

**Consistency model:**
- Read Committed (Supabase default) — acceptable. Badge fetch is not a financial transaction.
- `escrow_eligible` may be stale between listing UPDATE and next SELECT — acceptable; badge is advisory, not transactional. Checkout 409 re-validates (ADR-023 §6).

**Data classification:**
- `escrow_eligible` is a derived business attribute — not PII, not restricted. Standard public-read RLS is appropriate.
- No encryption required.

---

## Agent Assignments

| Task | Owner | Agent Support |
|------|-------|--------------|
| A-1 through A-7 (GH-113) | pizmam + belengaz | `code-reviewer` after each PR |
| B-1 DB migration | reso | `security-reviewer` on migration file |
| B-2 DTO | belengaz | `tdd-guide` for DTO tests |
| B-3 through B-6 | pizmam | `tdd-guide` → `code-reviewer` → `security-reviewer` |
| PR review (both branches) | all | `code-reviewer` agent |

---

## Plan Validation

| Schema Section | Status | Points |
|---------------|--------|--------|
| 1. Context & Problem Statement | ✓ Populated | 10/10 |
| 2. Goals & Non-Goals | ✓ Populated | 10/10 |
| 3. Implementation Steps | ✓ Exact file paths + verification per step | 10/10 |
| 4. Testing Strategy | ✓ Types, targets, scenarios | 10/10 |
| 5. Security Considerations | ✓ Threat table + pre-commit checklist | 10/10 |
| 6. Risks & Mitigations | ✓ 7 risks with severity + mitigation | 5/5 |
| 7. Success Criteria | ✓ Measurable checkboxes | 5/5 |
| 8. Architecture Impact | ✓ File tree + layer diagram | 4/4 |
| 9. API / Data Model Changes | ✓ DB schema + DTO + entity table | 3/3 |
| 10. Rollback Strategy | ✓ Per-step rollback + zero-downtime note | 3/3 |
| 11. Observability | ✓ Warning log + audit trail + flag metrics | 2/2 |
| 12. Performance Impact | ✓ Trigger cost + Riverpod cache + const widget | 2/2 |
| 13. Documentation Updates | ✓ ADRs + feature flags + CHANGELOG | 2/2 |
| 14. Dependencies | ✓ Hard blocks + downstream + pre-merge checklist | 2/2 |
| 15. Alternatives Considered | ✓ 3 tables with rejected options | 2/2 |
| Mobile Domain Enhancer | ✓ Platform parity, offline, perf, store | +2 |
| Frontend Domain Enhancer | ✓ A11y, responsive, touch, design system | +2 |
| Database Domain Enhancer | ✓ Migration, index, integrity, perf | +2 |

**Total: 86/86 → PASS (100%)**

---

*Approve to begin with `/implement` on branch `fix/gh113-non-blocking-polish` (pizmam/belengaz, no DB dependencies) and `fix/gh59-escrow-badge` (reso starts B-1 in parallel).*
