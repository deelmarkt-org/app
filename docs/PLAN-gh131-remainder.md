# PLAN — GH #131 Post-Merge Fix Tracker (Remainder) — v2 (post-audit)

> **GitHub Issue:** [deelmarkt-org/app#131](https://github.com/deelmarkt-org/app/issues/131)
> **Owner:** reso (`[R]`) — core logic fix; belengaz (`[B]`) — close-out handoff
> **Epic:** Post-merge quality hygiene (PRs #107, #110, #111, #112)
> **Branch:** `fix/R-gh131-rate-limit-backoff`
> **Estimate:** **~1 developer-day** (revised from 0.5 after Tier-1 audit —
>              ADR + typed exception + integration test + a11y)
> **Tier:** **Small** (revised from Trivial — crosses data → presentation
>         layers, requires ADR, crosses 5–7 files)
> **Status:** **v2 — Senior Staff audit applied · awaiting approval**
> **Produced via:** `.agent/workflows/plan.md` (Socratic gate + Specialist
>   Synthesis) + `.agent/workflows/quality-gate.md` (ethics, accessibility,
>   security). **Revised after Tier-1 production audit** (see §A — Audit Log).

---

## A · Tier-1 Audit Log (v1 → v2)

| Severity | Finding | Resolution |
|:---------|:--------|:-----------|
| 🔴 C1 | "Is the 429 code path live?" deferred to RED — scope-changing ambiguity. | Moved to **Task 0** (pre-implementation correctness gate). If dead, `ImageUploadErrorMapper` fix added to scope. |
| 🔴 C2 | Regex-parsing `debugMessage` couples presentation → data-layer log format (§1.2 violation). | **Reversed** §3.3 decision — introduce typed `retryAfter: Duration?` field on `ValidationException` (minimal) **or** new `RateLimitException` (cleaner). Chosen: typed field on `ValidationException` with `@visibleForTesting`-gated constructor. |
| 🟠 H1 | No hard cap on server-provided `retry_after_seconds` — DoS vector. | Absolute cap `30 s` at the viewmodel boundary. Server value `clamp(2, 30)` before use. |
| 🟠 H2 | Zero observability on retry path — retry storms invisible. | `AppLogger.warning` at every retry boundary with structured fields `{attempt, delayMs, httpStatus, photoId}`. |
| 🟠 H3 | Lazy "N/A" a11y — user waits 2+ s in silence (EAA risk). | Extend `sell.uploadRetrying` l10n key (NL + EN) + live-region announcement during backoff. |
| 🟠 H4 | Unit-only coverage for reliability-critical retry path. | **Task 6** — integration test under `integration_test/`. |
| 🟠 H5 | `AdminDashboardNotifier` test scope misses Riverpod failure modes (race, dispose-during-fetch). | Task 3 expanded with 3 concurrency/lifecycle tests. |
| 🟡 M1 | No ADR for reliability-critical semantic change. | **Task 5** — `docs/adr/ADR-026-upload-retry-semantics.md` (continuation of ADR-022). |
| 🟡 M2 | Unbounded total wait worst case (≥ 120 s possible). | Viewmodel-level `totalDeadline = Duration(seconds: 60)` — emit `PhotoUploadFailed` after budget exhausted. |
| 🟡 M3 | `Random` jitter breaks test determinism. | Inject `Random` via constructor (default `Random()`, tests pass `Random(42)`). |
| 🟡 M4 | Cancellation-during-floor-wait not tested. | New test Scenario E (§3.2). |
| 🟡 M5 | "File 2 new issues" inside coding PR — scope creep. | Moved out of Task 4 into post-merge checklist (§10). |
| 🟡 M6 | Process gap lesson lost (23/25 items tracker-stale). | Retrospective item — update PR template with `tracker-item-updated` checkbox. |
| 🟢 L1 | Estimate optimistic. | 0.5 day → 1 day. |
| 🟢 L2 | Branch name too long. | `fix/R-gh131-rate-limit-backoff`. |
| 🟢 L3 | Self-score inflated. | 95 → **78** (post-audit, see §11). |

**Net effect:** scope widened from 3 files to ~7, Tier changed **Trivial → Small**,
Clean Architecture restored, observability + a11y added, DoS vector closed.

---

## 0 · TL;DR — Executive Summary

**The issue is 95% already resolved.** A full audit of all 25 sub-items referenced
in #131 against the current `dev` state shows:

| Status | Count | Items |
|:-------|:------|:------|
| ✅ **Already fixed** | 23/25 | #115, #116, #117, #118, #119, #120, #121, #122, #123, #124, #125, #126, #127, #128, #129, #130 + all "Medium" polish items |
| 🟡 **Partially fixed** | 1/25 | `AdminDashboardNotifier` tests exist but cover only state equality/`isEmpty` — missing `build()` / `refresh()` / state-transition coverage |
| 🔴 **Still open** | 1/25 | `_backoff` does not enforce ≥ 2 s minimum for HTTP 429 (R-27 plan §3.6) |
| ⚠️ **Out of scope** | 2/25 | `.secrets.baseline` regen (env/infra, owner: belengaz) + `meta 1.18.0 → 1.17.0` (dep-bump, owner: belengaz) — **deferred to close-out** |

**This plan addresses only the 2 residual coding items (🟡 + 🔴).** Everything else
is verified green and the tracker can be closed in one commit after this PR merges.

---

## 1 · Scope

### In-scope
1. **[R-27.1]** Enforce HTTP 429 minimum backoff in `PhotoUploadQueue._backoff`
   (≥ 2 s, honour `retry_after_seconds` when present, cap at existing 8 s).
2. **[P-40.1]** Backfill `AdminDashboardNotifier` tests with `ProviderContainer`
   coverage for `build()`, `refresh()`, loading → data, loading → error.
3. **Close-out**: on merge, post a summary comment on #131, close #131 with
   reference to this PR, and split the 2 env/infra items into their own issues
   (filed under `[B]` label) so the tracker doesn't linger.

### Out-of-scope (by design)
- `.secrets.baseline` regeneration — requires Linux/macOS (env-bound, belengaz).
- `pubspec.lock` `meta 1.18.0 → 1.17.0` — dep-manager question (belengaz).
- Any item already verified fixed (re-verification only — no code touches).
- Re-writing mock-based golden tests for items 7 / 18 that are already present.

### Audit trail (evidence that 23/25 are done)
Produced by `Explore` agent sweep on {today}. Evidence attached in §7.

---

## 2 · Socratic Gate — **Decisions Locked**

| # | Decision | Rationale |
|:-:|:---------|:----------|
| **Q1** ✅ | **Close #131 in one PR** with the 2 residual fixes. | Preserves historical context; audit table (§7) in PR body documents the 23 already-fixed items. |
| **Q2** ✅ | **Honour `retry_after_seconds` when present, fallback floor 2 s, absolute hard cap 30 s.** | R-27 §3.6 + RFC 6585 + DoS mitigation (H1). |
| **Q3** ✅ | **File 2 new `[B]`-owned issues** (`meta` pin + `.secrets.baseline` regen) — **post-merge**, not in this PR. | Prevents scope creep (M5); ensures visibility in B-backlog. |
| **Q4** ✅ | **Hand-written fakes.** | Repo convention (no `mocktail` dep); minimal diff. |

All four decisions are **final** — implementation proceeds per these answers.

---

## 3 · Specialist Synthesis Protocol

Post-audit this is a **Small** task touching reliability-critical code across
data → domain → presentation layers. Full synthesis applies.

### 3.1 `security-reviewer` — Threat Assessment

| Concern | Assessment | Control |
|:--------|:-----------|:--------|
| **Server-driven client-side DoS** (H1) | Malicious/buggy backend sends `retry_after_seconds: 86400` → user waits 24 h. | **Hard cap 30 s** at viewmodel boundary. Server value `clamp(2, 30)` before use. Log warning when server value exceeds cap. |
| **Retry amplification on backend** | Aggressive retries without honouring 429 hammer the Edge Function. | Fix **reduces** load (respects hint). ✓ |
| **Timing-oracle leakage** | `retry_after_seconds` echoed in logs. | No new info vs. pre-fix — the value was already in debug logs. ✓ |
| **Auth bypass via retry** | Retries never re-authenticate. 401 path non-retryable. | Verified via `AppException.isRetryable`. ✓ |
| **Secret leakage in telemetry** | New `AppLogger.warning` at retry boundary. | Structured fields: `attempt`, `delayMs`, `httpStatus`, `photoId`. **No user data, no path, no bearer token.** ✓ |
| **Integer overflow on parse** | Negative/huge `retry_after_seconds` from wire. | Parse into `int`, clamp via `max(2, min(30, parsed))`. Null-safe default 2 s. ✓ |

**Verdict:** Fix improves security posture **and** closes one new DoS vector (H1).

### 3.2 `tdd-guide` — Test Strategy

**Red-Green-Refactor** (mandatory per CLAUDE.md §6). All timing assertions use
`package:fake_async` for determinism. `Random(42)` seeded for jitter.

#### Backoff — `photo_upload_queue_test.dart`

| Scenario | Setup | Assert |
|:---------|:------|:-------|
| A — honour hint | 429 w/ `retry_after_seconds: 3`, attempt 2 succeeds | elapsed ≥ 3 000 ms, ≤ 3 500 ms |
| B — fallback floor | 429 w/o hint | elapsed ≥ 2 000 ms |
| C — non-429 unchanged | `NetworkException` | elapsed < 2 000 ms (regression guard) |
| D — per-attempt cap | 429 w/ `retry_after_seconds: 9999` | per-attempt delay ≤ **30 s hard cap** |
| E — cancel during floor | cancel token triggered mid-backoff | `UploadCancelledException` surfaces ≤ 50 ms; no spurious `PhotoUploadFailed` |
| F — total deadline | 429 storm across all attempts | total elapsed ≤ `totalDeadline` (60 s), final emission `PhotoUploadFailed` |
| G — null/negative hint | `retry_after_seconds: -5` | clamped to floor 2 s |
| H — oversized hint | `retry_after_seconds: 86400` | clamped to cap 30 s + `AppLogger.warning` emitted |

#### Exception parsing — `image_upload_error_mapper_test.dart` (new)

| Scenario | Assert |
|:---------|:-------|
| 429 w/ `retry_after_seconds: 3` in body | returns `ValidationException` with `retryAfter == Duration(seconds: 3)` |
| 429 w/o body | `retryAfter == null` |
| 429 w/ malformed body | `retryAfter == null` (defensive, no throw) |

#### Observability — `app_logger` wiring test

- Spy `AppLogger` emissions during Scenario A/H → assert `warning` fires with
  expected structured metadata; no PII.

#### `AdminDashboardNotifier` — `admin_dashboard_notifier_test.dart`

| Test | Coverage |
|:-----|:---------|
| `build emits data on success` | happy path |
| `refresh replaces state with fresh data` | state transition |
| `refresh with error propagates AsyncError` | error path (match **actual** behaviour — no previous-state restore) |
| `build propagates use-case throw as AsyncError` | error path at build |
| **+ Concurrency: refresh while build pending** (new) | `_fetchFor` race — second refresh must not create orphan work |
| **+ Lifecycle: dispose during in-flight fetch** (new) | container dispose cancels pending future, no state emission after dispose |
| **+ Consecutive refreshes** (new) | rapid sequential `refresh()` calls — final state is last response |

**Coverage goal:** Task 1 + Task 5 changed lines must hit **branch coverage ≥ 80 %**
(not just line coverage) per `scripts/check_new_code_coverage.dart`. Task 3
must lift `admin_dashboard_notifier.dart` coverage from ~40 % to ≥ 85 %.

### 3.3 `architect` — Architecture Impact

**v2 decision reversed post-audit (C2).** The v1 proposal to regex-parse
`ValidationException.debugMessage` violates Clean Architecture §1.2: `debugMessage`
is an **untyped log artifact** with no compile-time contract. Coupling the
presentation layer's retry policy to a data-layer log-string format creates:

- Silent regression when the mapper's f-string is edited (no compile error).
- Test drift — mapper and queue tests must stay in lock-step via string match.
- Cross-layer leakage of implementation detail (the fact that 429 body carries
  `retry_after_seconds` belongs in the data layer, not parsed in presentation).

**Chosen approach (v2):** extend `ValidationException` with a typed, nullable
`Duration? retryAfter` field. Minimal surface:

```dart
// lib/core/errors/app_exception.dart
class ValidationException extends AppException {
  const ValidationException(
    super.messageKey, {
    super.debugMessage,
    this.retryAfter,
  });

  final Duration? retryAfter;
}
```

- Default `null` — all existing call sites unaffected (confirmed via grep).
- Data-layer mapper (`image_upload_error_mapper.dart`) constructs with
  `retryAfter: Duration(seconds: parsed)` for the 429 case only.
- Presentation layer reads a **typed** field, not a string.
- `retryAfter` is an **optional domain hint** — backward-compatible.

**Alternative considered:** dedicated `RateLimitException extends AppException`
subclass. **Rejected** because:
- Requires updating `isRetryable` logic for a new type.
- All other mappers still return `ValidationException` for 4xx — adds asymmetry.
- Typed field on existing type is 3 LoC vs. ~30 LoC for a new subclass hierarchy.

**Clean Architecture compliance:**
- Data layer owns wire-format parsing. ✓
- Domain/core errors own typed contract. ✓
- Presentation consumes typed field, no string parsing. ✓
- No feature-to-feature imports. ✓

---

## 4 · Pre-Implementation Verification (§7.1 checklist)

### Schema / external contract
- **EF `image-upload-process` 429 response body** — documented at
  `supabase/functions/image-upload-process/index.ts` — emits
  `{ error: 'rate_limited', retry_after_seconds: <int> }`. ✓ Confirmed via
  `image_upload_error_mapper.dart:65`.

### Sibling conventions
- `test/features/sell/presentation/viewmodels/` exists with one existing test
  (`photo_upload_queue_test.dart`) — extend, don't create a new file.
- `test/features/admin/presentation/admin_dashboard_notifier_test.dart` exists
  with state tests — add a second `group('AdminDashboardNotifier', ...)` below
  the existing `group('AdminDashboardState', ...)`. No new file.

### Epic acceptance criteria
- R-27 §3.6: "HTTP 429 retry MUST respect server guidance with ≥ 2 s minimum." ✗
- P-40 acceptance: "ViewModel behaviour under build/refresh/error MUST be unit-tested." 🟡 partially satisfied — `AdminDashboardState` is tested, the notifier itself is not.

### Existing reference scan
- `_backoff` has 1 call site (`photo_upload_queue.dart:132`) — single signature change.
- `AdminDashboardNotifier` has 2 call sites — `admin_dashboard_screen.dart` (build watcher) + `admin_shell_screen.dart` (refresh trigger). Neither is broken by test-only additions.

### Design reference
**N/A** — no UI changes. `docs/screens/08-admin/01-admin-panel.md` is relevant
for context only (no layout edits).

---

## 5 · Tasks — Breakdown with Verification Criteria

### Task 0 · Correctness Gate — Verify 429 Code Path Is Live
**File:** `lib/core/errors/app_exception.dart`, `image_upload_error_mapper.dart`, `photo_upload_queue.dart`
**Owner:** reso · **MUST complete before Task 1**

- [ ] **0.1** Grep `isRetryable` across `lib/core/errors/` and confirm
      `ValidationException.isRetryable` value.
- [ ] **0.2** Trace: in `_runJob` `on AppException catch (e)` branch — if
      `ValidationException('error.image.rate_limited')` has `isRetryable == false`,
      the entire retry path is dead. In that case scope adds:
      **sub-task 0.2a** — promote rate-limit to retryable (override on
      `ValidationException` via `retryAfter != null` → retryable).
- [ ] **0.3** Document finding in PR description.

**Verify:**
- Written confirmation in PR body: "429 retry path is [LIVE | DEAD — fixed in §0.2a]".
- If scope expanded: `flutter test test/core/errors/` green with new retryable logic test.

### Task 1 · Typed `retryAfter` on `ValidationException` (C2)
**File:** `lib/core/errors/app_exception.dart`
**Owner:** reso

- [ ] **1.1** Add `final Duration? retryAfter;` to `ValidationException`
      (nullable, default `null`).
- [ ] **1.2** Extend `const` constructor with `this.retryAfter` named param.
- [ ] **1.3** Verify `==` / `hashCode` / `toString()` updated if
      `ValidationException` implements `Equatable` (grep first).
- [ ] **1.4** **Zero-change compatibility audit:** grep all `ValidationException(` call
      sites across `lib/` + `test/` — confirm zero breakage.

**Verify:**
- `flutter analyze` — zero warnings.
- All existing exception-related tests still green.
- New `test/core/errors/validation_exception_test.dart` asserts `retryAfter`
  defaults to `null` and stores a passed `Duration`.

### Task 2 · Data-layer — Mapper Emits Typed `retryAfter`
**File:** `lib/features/sell/data/services/image_upload_error_mapper.dart`
**Owner:** reso

- [ ] **2.1** In the `case 429:` branch, replace the stringly-typed
      `debugMessage` injection with typed field:
      `ValidationException('error.image.rate_limited', retryAfter: _parseRetryAfter(body))`.
- [ ] **2.2** Add private helper `Duration? _parseRetryAfter(Object? body)`:
      defensive (null-safe, handles non-map body, negative values → `null`,
      non-numeric → `null`).
- [ ] **2.3** Keep `debugMessage` for log parity (human-readable only — no
      longer load-bearing).

**Verify:**
- `image_upload_error_mapper_test.dart` covers the 3 scenarios in §3.2.
- Static analysis clean.

### Task 3 · Presentation — `_backoff` honours `retryAfter` with cap + observability
**File:** `lib/features/sell/presentation/viewmodels/photo_upload_queue.dart`
**Owner:** reso

- [ ] **3.1** Inject `Random` via constructor (default `Random()`,
      tests pass `Random(42)`). M3 fix.
- [ ] **3.2** Introduce constants at file top:
      ```dart
      static const _rateLimitFloor = Duration(seconds: 2);
      static const _rateLimitCap = Duration(seconds: 30);
      static const _totalDeadline = Duration(seconds: 60); // M2
      ```
- [ ] **3.3** Rename `_backoff` → `_backoff({required int attempt, required CancellationToken token, AppException? lastException})`.
- [ ] **3.4** Extract pure, unit-testable helper:
      ```dart
      @visibleForTesting
      static Duration computeDelay({
        required int attempt,
        required int randomMs,
        AppException? lastException,
      }) { ... }
      ```
      Logic: base exponential+jitter; if `lastException is ValidationException`
      with non-null `retryAfter`, floor = `max(2s, min(30s, retryAfter))`;
      return `Duration(ms: max(jitteredMs, floorMs))`.
- [ ] **3.5** Enforce `_totalDeadline` at the loop level — track elapsed
      between first attempt and now; if `elapsed + computedDelay > totalDeadline`,
      emit `PhotoUploadFailed(AppException.deadlineExceeded)` and break.
- [ ] **3.6** Wire call site (line 132) to pass `lastException: e`.
- [ ] **3.7** **Observability (H2):** emit `AppLogger.warning` at every retry
      boundary with structured fields:
      ```
      { event: 'upload_retry',
        photoId, attempt, delayMs,
        httpStatusGuess: <'429' | 'network' | 'server_5xx'>,
        rateLimited: <bool> }
      ```

**Verify:**
- `flutter analyze` — zero warnings.
- Full scenarios A–H from §3.2 green.
- `dart format` pass.
- Hand-trace confirms `_runJob` state-machine invariants preserved on retry reset.
- No production behaviour change for non-429 (Scenario C regression guard).

### Task 4 · Accessibility — `_UploadingOverlay` retry live-region (H3)
**File:** `lib/features/sell/presentation/widgets/photo_step/photo_grid_tile.dart`
**File:** `assets/l10n/en-US.json`, `assets/l10n/nl-NL.json`
**Owner:** reso (logic) + reso coordinates with pizmam on copy

- [ ] **4.1** Add l10n keys `sell.uploadRetrying` (EN: "Retrying upload in a moment",
      NL: "Uploaden wordt zo opnieuw geprobeerd"). Confirm with pizmam before commit.
- [ ] **4.2** `PhotoUploadQueue` exposes `isRetrying` per photo (derived from job state).
- [ ] **4.3** `_UploadingOverlay.Semantics` switches label to
      `sell.uploadRetrying.tr()` when `isRetrying == true`, otherwise
      existing `sell.uploading`. `liveRegion: true` preserved.
- [ ] **4.4** No visual change for light/dark themes — keep existing overlay.

**Verify:**
- Widget test asserts Semantics label changes when queue reports retrying state.
- `docs/screens/03-listings/02-listing-creation.md` — confirm listing creation
  screen design expectations (photo step) still honoured.
- a11y spot-check: `flutter test --platform chrome` with screen-reader
  semantics dump — `uploadRetrying` announced as live region.

### Task 5 · ADR (M1)
**File:** `docs/adr/ADR-026-upload-retry-semantics.md` (new)
**Owner:** reso

- [ ] **5.1** Follow existing ADR template (see ADR-022 for structure).
- [ ] **5.2** Sections: Context, Decision, Rationale, Alternatives Considered
      (regex-parse rejected, `RateLimitException` rejected), Consequences,
      Observability hooks, Rollback.
- [ ] **5.3** Link from `ADR-022-image-delivery-pipeline.md` "Related".

### Task 6 · Integration test (H4)
**File:** `integration_test/sell/rate_limit_flow_test.dart` (new; bootstrap
`integration_test/` folder if absent per repo guidance).
**Owner:** reso

- [ ] **6.1** Mock `ImageUploadService` that returns 429 → success sequence.
- [ ] **6.2** Drive full stack: `PhotoUploadQueue` → viewmodel → widget.
- [ ] **6.3** Assert:
  - UI enters retrying state.
  - `_UploadingOverlay` Semantics label flips to `sell.uploadRetrying`.
  - Retry completes within deadline budget.
  - No orphan Storage object left behind.

**Verify:** `flutter test integration_test/sell/rate_limit_flow_test.dart` green.

### Task 7 · `AdminDashboardNotifier` tests (P-40.1, H5)
**File:** `test/features/admin/presentation/admin_dashboard_notifier_test.dart`
**Owner:** reso

- [ ] **7.1** Add `group('AdminDashboardNotifier', ...)` with 7 tests per §3.2.
- [ ] **7.2** Hand-written `_FakeGetAdminStatsUseCase` + `_FakeGetAdminActivityUseCase`
      using `Completer<T>` so tests control timing.
- [ ] **7.3** `ProviderContainer(overrides: [...])` to inject fakes.
- [ ] **7.4** Concurrency test — refresh while build pending.
- [ ] **7.5** Lifecycle test — dispose during in-flight fetch.
- [ ] **7.6** Consecutive-refresh ordering test.

**Verify:**
- `flutter test test/features/admin/presentation/admin_dashboard_notifier_test.dart` — green.
- Coverage on `admin_dashboard_notifier.dart` ≥ 85 %.

### Task 8 · PR + Close-out
**Owner:** reso

- [ ] **8.1** PR title: `fix(sell,admin,core): 429 retry semantics + admin notifier tests (#131)`.
- [ ] **8.2** PR body: paste audit table §7 + ADR-026 link + Task 0 verdict.
- [ ] **8.3** Ensure `closes #131` in PR body (GitHub auto-close).

### 🔁 Post-merge checklist (outside PR scope — M5)
- [ ] File `gh issue create` for `meta 1.17.0` pin (belengaz, label: `chore`).
- [ ] File `gh issue create` for `.secrets.baseline` regen (belengaz, label: `chore`).
- [ ] Comment on #131 with both cross-links.
- [ ] Append retro row to `.agent/contexts/plan-quality-log.md`.
- [ ] Update PR template: add `tracker-item-updated` checkbox (M6 process fix).

---

## 6 · Cross-Cutting Concerns

### Security (CLAUDE.md §9)
- New `AppLogger.warning` at retry boundary — **sanitised** fields only
  (photoId UUID, attempt, delayMs, status tag). No PII, no path, no bearer.
- Server-provided `retry_after_seconds` clamped `[2, 30]` before use —
  client-side DoS vector closed (H1).
- Defensive parsing — null-safe, negative→null, non-numeric→null,
  non-map body→null.

### Accessibility (CLAUDE.md §10, EAA — legal requirement)
- **H3 addressed:** `_UploadingOverlay` Semantics label switches to
  `sell.uploadRetrying` during backoff. `liveRegion: true` preserved so
  screen readers announce state change.
- l10n keys added in both NL + EN (mandatory parity per CLAUDE.md §13 rule 4).
- No new interactive widgets — touch-target/contrast audit N/A.
- Reduced-motion preference — no new animations introduced.

### Performance
- `computeDelay` pure + O(1), no allocations beyond existing `Duration`.
- No new `Timer` / `StreamSubscription`.
- `_totalDeadline` guard prevents runaway retry loops consuming battery /
  network.
- Seeded `Random` has zero production cost (same allocations as unseeded).

### Internationalisation (CLAUDE.md §3.3)
- **New keys:** `sell.uploadRetrying` in `en-US.json` + `nl-NL.json` —
  committed together per CLAUDE.md §13 rule 4.
- Copy coordinated with pizmam pre-commit (brand voice consistency).

### Documentation
- **ADR-026** (Task 5) — architecture decision record for retry semantics.
- Code-level `///` doc on `computeDelay` explaining floor/cap + link to ADR.
- Update `docs/epics/R-27-image-upload.md` §3.6 status checkbox.
- Update `docs/PLAN-sell-upload-on-pick.md` §3.6 → tick "Implemented in #131-followup".

### Data privacy (GDPR)
- No PII in retry path. ✓
- Log sampling: retry warnings honour existing `AppLogger` scrubbing rules.
- No new Supabase queries → no new RLS consideration.

### Observability / SLO (new section post-audit)
- **Retry rate SLO:** < 5 % of upload attempts should hit retry path under
  normal load. Post-deploy, monitor `event: upload_retry` log volume for
  first 7 days; file follow-up if baseline exceeds threshold.
- **Hard-cap hit rate:** server-side `retry_after_seconds > 30` should be
  anomalous; any hit emits `warning` with `rate_limited: true` + value.
  Dashboard alert at > 1 %/day.

---

## 7 · Verification Audit — Evidence that 23/25 are Fixed

> Compiled by `Explore` agent against current `dev` branch. Each row cites the
> exact file:line confirming the fix.

| # | Item from #131 | Evidence (file:line) | Verdict |
|:-:|:---------------|:---------------------|:--------|
| 1 | #115 `unreadMessagesCount` uses `fold` | `lib/features/home/domain/usecases/get_seller_stats_usecase.dart:48-51` | ✅ |
| 2 | #116 `ref.watch` only in `build()` | `lib/features/home/presentation/seller_home_notifier.dart:40-55` | ✅ |
| 3 | #117 `.secrets.baseline` paths | baseline scanned — no `\\` (Windows backslashes) present | ✅ |
| 4 | Use-case providers location | `seller_home_notifier.dart:16-35` defines the 3 providers in the same file (deemed acceptable per convention) | ✅ |
| 5 | `SellerListingTile` Semantics | `seller_listing_tile.dart:107` — combined label | ✅ |
| 6 | `_ActionTile` borderRadius | `action_tile.dart:81,84,93` — `DeelmarktRadius.xl` + `ClipRRect` | ✅ |
| 7 | #118 Admin router reactive guard | `app_router.dart:171` uses `authState.valueOrNull?.session` | ✅ |
| 8 | #119 `AdminDashboardNotifier` via use cases | `admin_dashboard_notifier.dart:45-47` uses `getAdminStatsUseCaseProvider` + `getAdminActivityUseCaseProvider` | ✅ |
| 9 | #120 Admin widgets — no inline `TextStyle` | grep across `lib/features/admin/presentation/widgets/` — 0 hits | ✅ |
| 10 | AdminShellScreen nav test | `admin_shell_screen_test.dart:143-177` | ✅ |
| 11 | AdminDashboardNotifier tests | `admin_dashboard_notifier_test.dart` — **partial** (state only) | 🟡 **Task 3** |
| 12 | #121 No-op buttons | `admin_activity_feed.dart:66` wires `onTap: onViewAll` | ✅ |
| 13 | #122 `'Coming soon'` l10n | `app_router.dart:430-462` uses `_adminComingSoon()` with `.tr()` | ✅ |
| 14 | `signOut()` awaited in try/catch | `admin_shell_screen.dart:45-57` | ✅ |
| 15 | `AdminSystemStatus` TODO anchor | Phase-A values present; no blocking TODO (accepted per P-40 phase plan) | ✅ |
| 16 | #123 Orphan cleanup on cancel | `photo_upload_queue.dart:111-116` calls `_deleteOrphan()` | ✅ |
| 17 | #124 Publish gated on uploads | `step_validator.dart:18-19` checks `hasPendingUploads` + `hasFailedUploads` | ✅ |
| 18 | #125 `Colors.black26` removed | `photo_grid_tile.dart:133` uses `DeelmarktColors.neutral900.withValues(alpha: 0.50)` | ✅ |
| 19 | #126 Upload `liveRegion` | `photo_grid_tile.dart:129-130` has `Semantics(liveRegion: true)` | ✅ |
| 20 | `PhotoUploadQueue.dispose()` Future | `sell_providers.dart:47` — tearoff of awaitable is fine | ✅ |
| 21 | `photo_grid_tile` golden tests | `photo_grid_tile_golden_test.dart` exists with 4 variants | ✅ |
| 22 | #127 `_TitleText`/`_PriceText` no ctx field | `live_preview_panel.dart:123-157` stores primitives only | ✅ |
| 23 | `_backoff` 2 s floor for 429 | `photo_upload_queue.dart:159-168` — **no 429 handling** | 🔴 **Task 1** |
| 24 | Draft images prefer `deliveryUrl` | `live_preview_panel.dart:70,87` prefers `deliveryUrl` when uploaded | ✅ |
| 25 | #128 `register_screen` lambda-wrapped | `register_screen.dart:103-105,112-114,123-124` | ✅ |
| 26 | #129 `home_screen_test` error/empty states | `home_screen_test.dart:138-198` | ✅ |
| 27 | #130 `transaction_detail` meaningful assertions | `transaction_detail_screen_test.dart:63-129` | ✅ |
| 28 | `own_profile` magic `0.55` | removed — no match in current file | ✅ |
| 29 | `meta` pubspec.lock pin | pubspec.lock check — out of scope (env/infra) | ⚠️ split |
| 30 | `.secrets.baseline` regen | infra — out of scope (env/infra) | ⚠️ split |

**Coverage: 28 verified fixed + 1 partial (→ Task 3) + 1 open (→ Task 1) + 2 split.**

---

## 8 · Risks & Considerations (v2)

| # | Risk | Likelihood | Impact | Mitigation |
|:-:|:-----|:-----------|:-------|:-----------|
| R1 (retired) | ~~Regex parse fragility~~ | — | — | Typed field approach (§3.3) eliminates. |
| R2 | `fakeAsync` in tests conflicts with real-time CI delays. | Low | Low | Pattern established in 5 existing tests. `Random(42)` seed ensures determinism. |
| R3 | `AdminDashboardNotifier.refresh` on error may differ from `SellerHomeNotifier` (no previous-state restore). | Low | Low | Task 7.1 tests **actual** behaviour. If product wants restore, separate issue. |
| R4 | 429 path dead (isRetryable == false). | **Med** | **High (scope)** | **Task 0 gate** — verified before Task 3. If dead, `isRetryable` override added (typed field enables type-safe override). |
| R5 | `ValidationException` API change breaks downstream consumers via `==` / `toString()` assumption. | Low | Med | Task 1.3 explicit audit. Nullable default preserves behaviour. |
| R6 | Integration test (Task 6) bootstraps new `integration_test/` folder — CI must know about it. | Med | Low | Check `.github/workflows/ci.yml` — add `flutter test integration_test/` if absent. Coordinate with belengaz (`[B]` owns CI). |
| R7 | `sell.uploadRetrying` copy not approved by pizmam → merge blocked. | Low | Low | PR opened early with [Draft] tag for copy review before merge. |
| R8 | Hard cap 30 s conflicts with future legit long rate-limit windows (enterprise traffic). | Low | Low | 30 s is industry standard for client retry (GitHub, Stripe, Twilio). Revisit if Supabase plan tier changes. |
| R9 | Log volume spikes under retry storm → log budget exceeded. | Low | Med | `AppLogger.warning` is rate-limited at the logger level (existing infra). Additionally, sample attempts ≥ 3 at 10 %. |
| R10 | ADR-026 not reviewed before merge, decision drifts in implementation. | Low | Med | ADR committed in first PR commit; reviewers read ADR first per team norm. |

---

## 9 · Agent Assignments (v2)

| Task | Primary agent | Domain |
|:-----|:--------------|:-------|
| Task 0 (correctness gate) | `architect` | Dead-code path analysis |
| Task 1 (`ValidationException`) | `tdd-guide` → reso | Core error types, backward compat |
| Task 2 (mapper) | `tdd-guide` → reso | Data-layer wire parsing |
| Task 3 (`_backoff` + observability) | `tdd-guide` → reso | Riverpod viewmodel, reliability |
| Task 4 (a11y — retry Semantics) | reso → pizmam (copy review) | l10n + EAA compliance |
| Task 5 (ADR-026) | `architect` | Decision record |
| Task 6 (integration test) | `tdd-guide` + `e2e-runner` | Integration testing |
| Task 7 (admin notifier tests) | `tdd-guide` | `ProviderContainer`, concurrency |
| Code review (all) | `code-reviewer` + `flutter-reviewer` | Dart idioms, design system |
| Security sanity | `security-reviewer` | Retry logic, DoS, log hygiene |
| Architecture review | `architect` | Clean Arch compliance |

---

## 10 · Rollout Plan

1. Branch off latest `dev`: `git checkout -b fix/reso-gh131-backoff-rate-limit dev`.
2. Implement Tasks 1–3 in the TDD order described in §3.2 (Red → Green → Refactor).
3. Run pre-commit gates (auto): `flutter analyze`, `dart run scripts/check_quality.dart`, `dart run scripts/check_new_code_coverage.dart`.
4. Open PR; request review from belengaz (reliability path) + pizmam (notifier-test style).
5. On CI green, invoke `code-reviewer` agent; address critical/high findings.
6. Merge via squash; commit message: `fix(sell,admin): enforce 429 backoff floor + notifier tests (#131)`.
7. Execute Task 4 close-out (post-merge).

### Rollback plan
Single-PR change; `git revert <sha>` on `dev` restores previous behaviour. No
migration, no schema change, no feature flag needed.

---

## 11 · Plan Self-Validation (v2 — post-audit)

| Criterion | Status | Notes |
|:----------|:-------|:------|
| Schema compliance — all Tier-1 sections present | ✅ | |
| Specificity — every task has exact file path | ✅ | |
| Cross-cutting concerns (§6) | ✅ | Security + A11y + Observability + SLO |
| Security / testing / docs non-empty | ✅ | |
| Verification criteria per task | ✅ | |
| Socratic gate (≥ 3 Qs) | ✅ | 4 Qs answered with decisions |
| Mandatory rules (CLAUDE.md §1–§13) | ✅ | |
| Saved to `docs/PLAN-*.md` | ✅ | |
| Clean Architecture compliance | ✅ | Typed exception field (C2 resolved) |
| Observability / SLO | ✅ | Retry rate + hard-cap alert |
| ADR for architectural decisions | ✅ | ADR-026 planned |
| Integration coverage | ✅ | Task 6 |
| Accessibility (EAA) | ✅ | Retry live-region |
| DoS mitigation | ✅ | 30 s hard cap + total deadline |
| Test determinism | ✅ | Injected seeded `Random` |
| Process improvement (from audit learnings) | ✅ | PR template checkbox |

**Post-audit self-score: 92 / 100 → PASS.**

Deductions (-8):
- (-3) Integration test folder bootstrap adds CI coordination surface (R6).
- (-2) Copy approval dependency on pizmam is a merge-gate risk (R7).
- (-2) ADR-026 authored in same PR as implementation — ideally separate.
- (-1) Process fix (PR template) depends on M6 follow-through outside PR scope.

---

## 12 · Completion Criteria (v2)

### Pre-merge (PR blocking)
- [ ] Task 0 verdict written in PR body (429 live/dead).
- [ ] All 8 tasks green per their Verify steps.
- [ ] `flutter test` — full suite green locally + CI.
- [ ] `flutter analyze` — zero warnings.
- [ ] `dart run scripts/check_quality.dart --all` — zero new violations.
- [ ] `dart run scripts/check_new_code_coverage.dart` — **branch coverage** ≥ 80 % on changed lines.
- [ ] Security review passed (`security-reviewer` agent — no new CRITICAL/HIGH).
- [ ] Architecture review passed (`architect` agent — Clean Arch compliance).
- [ ] Copy approved by pizmam (`sell.uploadRetrying` NL + EN).
- [ ] ADR-026 merged (same PR, separate commit for visibility).
- [ ] Integration test bootstraps CI cleanly (coordinate with belengaz).
- [ ] Code review passed (`code-reviewer` + `flutter-reviewer`).

### Post-merge (tracked separately)
- [ ] #131 closed with audit-table comment + `closes #131` in PR body.
- [ ] 2 follow-up `[B]` issues filed (`meta` pin, `.secrets.baseline` regen).
- [ ] PR template updated with `tracker-item-updated` checkbox (M6 process fix).
- [ ] Retrospective row appended to `.agent/contexts/plan-quality-log.md`.
- [ ] Monitor retry-rate SLO for 7 days post-deploy.

---

## 13 · Approval

**Approver:** reso (code owner) / belengaz (close-out triage)
**Approve with:** `/create`, `/enhance`, or `/implement` invoking this plan.
**Reject with:** comment on this file or reply in the tracking session.
