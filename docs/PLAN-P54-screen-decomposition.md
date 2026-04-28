# PLAN-P54 — Decompose 9 over-budget screens (CLAUDE.md §2.1)

> **Implementation note (PR #244 follow-up):** the primitive named `SkeletonBone`
> throughout this plan shipped as `SkeletonBox` inside
> [`lib/widgets/feedback/skeleton_shapes.dart`](../lib/widgets/feedback/skeleton_shapes.dart),
> alongside `SkeletonLine` and `SkeletonCircle`. PR-D1 ✅ shipped under that name;
> PR-D2 (`detail_loading_view.dart`) ✅ consumes it. Treat every `SkeletonBone`
> reference below as `SkeletonBox` until this plan is rewritten.

> **Owner:** 🔵 pizmam (`@emredursun`) · **Co-review on payment scope:** 🟢 belengaz (`@mahmutkaya`) · **Architecture spot-check:** 🔴 reso (`@MuBi2334`)
> **Severity / Audit ref:** P2 / `M1` (preflight) · `P-54` (retrospective)
> **Effort:** L — **3–4 weeks calendar** (1.5 weeks active dev + reviewer cycles + soak windows)
> **Workflow:** `/plan` v2.2.0 + `/quality-gate` v2.1.0 + Specialist Synthesis Protocol + Tier-1 Self-Audit (v2)
> **Task size:** **Large** (~30 new files across 7 feature folders + 2 shared primitives + tooling artefacts)
> **Created:** 2026-04-26 · **Audited:** 2026-04-26 (v2 — 22 amendments applied) · Status: ⏳ Awaiting approval

> **Plan version history**
> - v1 (commit `baad1aa`): initial plan, architect + tdd-guide synthesis
> - v2 (this revision): 22 amendments applied from Tier-1 Senior Staff self-audit — 6 CRITICAL (C1–C6), 6 HIGH (H1–H6), 6 MEDIUM (M1–M6), 4 LOW (L1–L4)

---

## 1. Context (the "why")

CLAUDE.md §2.1 caps screen widgets at **200 lines** and feature widgets at the same. **9 files breach this cap** on `origin/dev` (verified post-PR-#220):

| # | File | LOC | Type |
|---|------|----:|------|
| 1 | `lib/features/transaction/presentation/screens/mollie_checkout_screen.dart` | **248** | Screen — payment-critical |
| 2 | `lib/features/messages/presentation/screens/chat_thread_screen.dart` | 228 | Screen — golden-test fragile (#203) |
| 3 | `lib/features/home/presentation/screens/category_detail_screen.dart` | 228 | Screen |
| 4 | `lib/features/listing_detail/presentation/widgets/detail_loading_view.dart` | 225 | Widget |
| 5 | `lib/features/search/presentation/widgets/search_results_view.dart` | 225 | Widget |
| 6 | `lib/features/home/presentation/widgets/home_data_view.dart` | 209 | Widget |
| 7 | `lib/features/listing_detail/presentation/listing_detail_screen.dart` | 205 | Screen |
| 8 | `lib/features/profile/presentation/screens/appeal_screen.dart` | 205 | Screen |
| 9 | `lib/features/sell/presentation/screens/listing_creation_screen.dart` | 204 | Screen |

§2.1 is not a style preference — it's a forcing function for cohesion that prevents the "200 files, can't find anything" anti-pattern Linear's engineering blog identifies as the single biggest cause of frontend velocity decay. This PR series closes the breach.

This is a **pure refactor**: behaviour must be unchanged. Tier-1 standards require zero functional regression — proven by passing existing tests, +25 new test files, 240 unchanged golden bytes (or manually-reviewed shifts), and zero p95 trace regressions vs. the P-56 baseline.

---

## 2. Decisions Required (Socratic gate, pre-answered with specialist + audit input)

| # | Question | Decision | Rationale |
|---|----------|----------|-----------|
| **D1** | Mega-PR or split? | **10 PRs total**: 1 prep (#203) + 7 per-feature + 2 shared-primitive isolations (H2 split). | Per-feature scope ≤ 400 LOC, reviewable in one sitting. **H2:** primitives ship FIRST as standalone PRs to isolate primitive bugs from consumer migrations. |
| **D2** | Sub-widget construction kind | **`StatelessWidget` taking resolved values**. `ConsumerWidget` only when notifier method calls AND callback would require 4+ params. | Independent testability without `ProviderScope`; explicit data flow; single source of truth for rebuild graph. |
| **D3** | Naming convention | **Public `PascalCase`** when own file. **Private `_PascalCase`** only for inline helpers <30 LOC, never tested in isolation. | Addressable + importable + testable. Worth a §2.2 amendment. |
| **D4** | New shared primitives | **2 net new:** `SkeletonBone`, `DiscardChangesDialog`. Reject `BottomActionBar` shared primitive (Apple HIG: AppBars context-sensitive). | §3.1 "Will 2+ features use it?" rule satisfied for both. |
| **D5** | Payment refactor protocol | **Characterisation tests FIRST** + URL validator → `domain/` + 2-pass refactor + sandbox iDEAL test. Never extract `WebViewController` lifecycle. | Stripe checkout-WebView playbook; §6.1 100% payment coverage. |
| **D6** | chat_thread + #203 ordering | **Fix #203 in standalone PR-A1 FIRST**, prove stable across 3 CI runs, THEN decompose. Decomposition keeps `ScrollController` + `addPostFrameCallback` ownership in screen. | Avoid "did decomposition fix #203 by accident?" trap. |
| **D7** | Test obligation per extracted widget | **Smoke render** mandatory. **Semantics** test mandatory if interactive. **Interaction** test mandatory if it has a callback. **Golden** only if visually distinctive. | §6.2 floor not ceiling; Tier-1 (Stripe/Linear) practice. |
| **D8** | Mocking strategy | **`ProviderScope.overrides` + `Fake<EntityRepository>` from `test/mocks/`.** Override the *repository provider*, not Supabase client. | Matches §6.3 pattern; gives compile-time interface coverage + scriptable state transitions. |
| **D9** | Commit granularity | **One commit per file** (≥9 commits across 10 PRs), risk-ascending within each PR; standard message format. | Makes `git bisect run flutter test` mechanical. |
| **D10** | Test file organisation | **One test file per extracted widget**, co-located with source. Strictly enforce. | §2.1 300-line cap is a forcing function for cohesion. |
| **D11** | Extract vs inline thresholds | **Extract** when block has >3 testable behaviours OR independent reuse OR >30 LOC. **Inline** below those thresholds. | Premature extraction = "200 files, can't find anything." |
| **D12** | Documentation overhead | Each new widget: `///` doc (1-line purpose + screen-spec ref). **Parent does NOT gain children manifest.** | Apple SwiftUI + Linear React conventions; git blame is source of truth. |
| **D13** | Coverage gate strategy | Extract + write the test in the **same commit**. Run `check_new_code_coverage.dart` locally before push. | Co-commit discipline defuses the changed-lines gate. |
| **D14** | Goldens regeneration | **Byte-identical** for layout-identical extraction. Non-zero `git diff --stat test/screenshots/` requires manual visual diff review with **5% pixel-tolerance** allowance for anti-aliasing noise (M6); >5% = manual review. | Layout-equivalent semantic regressions (`liveRegion: true` lost) are golden-invisible. |
| **D15** ✨ | Mollie production rollout | **Unleash feature-flag gated rollout:** flag default `false` → T+24h staging soak → T+48h **5%** production → T+1w **100%** → T+2w flag removal. | **C1.** Stripe playbook for payment-critical refactors; never ship a code-path swap to all users at once. |
| **D16** ✨ | Accessibility regression detection | Beyond Semantics label tests: `dart run scripts/check_a11y.dart` (4.5:1 contrast, 44px touch, Semantics tree integrity) + manual VoiceOver/TalkBack on PR-A + PR-B (recorded as PR comment). | **C2.** EAA enforcement is live; Semantics-label-only is insufficient. |
| **D17** ✨ | Forbidden modifications | New §3.5 enumerates 8 categories of prohibited changes during P-54. | **C4.** Reduces "incidental changes" Tier-1 anti-pattern blast radius. |
| **D18** ✨ | Test coverage by layer | DoD #6 is split into 6a-6d: domain 100% / data ≥80% / stateful presentation ≥80% / pure UI ≥60%. | **C5.** Aggregate %80 can hide critical bugs. |
| **D19** ✨ | Performance regression budget vs P-56 traces | Pre-PR p95 baseline capture; T+48h post-merge comparison; **>10% regression = automatic revert**. `payment_create p95 +0% ±100ms` for PR-A. | **C6.** P-56 just shipped; P-54 must not invalidate it. |
| **D20** ✨ | Reviewer SLA | First review 24h, revisions 12h. PR-G blocked on PR-F → escalate to mahmutkaya at T+48h. PR-A requires belengaz primary + reso architecture spot-check. | **H1.** Reviewer bottleneck is the largest source of calendar slip on multi-PR series. |
| **D21** ✨ | Shared primitive isolation | `SkeletonBone` + `DiscardChangesDialog` ship in their own PRs (PR-D1, PR-F1) **before** any consumer PR. Each ≤200 LOC of source + tests. | **H2.** Primitive bugs blast all consumers if co-shipped. |
| **D22** ✨ | CI parallelism | Add `--concurrency=4` to flutter_test invocation; per-PR runtime budget +60s; aşılırsa test split. | **H3.** ~25 new test files = +60-90s without concurrency. |
| **D23** ✨ | Hotfix lane (Level 0 rollback) | New `hotfix/<scope>` branch + 30-min reviewer SLA + cherry-pick to `dev` + `main`. Distinct from revert paths. | **H4.** Forward-fix is sometimes safer than revert (e.g. database migration already applied). |
| **D24** ✨ | Per-file extract-vs-inline rationale | §3 per-file table gains "Extract vs Inline rationale" column making D11 application reviewable. | **H5.** Reviewers cannot validate D11 without per-file annotation. |

---

## 3. Per-file decomposition strategy

### Risk-ascending burn-down order

| Order | File | LOC → target | Risk | PR | Rationale |
|------:|------|-------------:|------|-----|-----------|
| 1 | `category_detail_screen.dart` | 228 → ~70 | LOW | PR-C | View-only; 3 in-file private classes — promote |
| 2 | `home_data_view.dart` | 209 → ~90 | LOW | PR-C | View-only; extract 2 sections, inline trivial helpers |
| 3 | `detail_loading_view.dart` | 225 → ~80 | LOW | PR-D2 | Skeleton blocks; consumes `SkeletonBone` from PR-D1 |
| 4 | `listing_creation_screen.dart` | 204 → ~110 | LOW | PR-G | Step-body switch + leading switch + discard dialog |
| 5 | `search_results_view.dart` | 225 → ~80 | MED | PR-E | Responsive layout coverage; split expanded vs compact |
| 6 | `appeal_screen.dart` | 205 → ~120 | MED | PR-F2 | Draft-save side-effect ordering; consumes `DiscardChangesDialog` from PR-F1 |
| 7 | `listing_detail_screen.dart` | 205 → ~80 | MED | PR-D2 | Share/clipboard side effects |
| 8 | `chat_thread_screen.dart` | 228 → ~140 | HIGH | PR-B | Golden fragility; depends on PR-A1 (#203 fix) |
| 9 | `mollie_checkout_screen.dart` | 248 → ~140 | **CRITICAL** | PR-A | Payment path; characterisation + URL validator + 2-pass + Unleash flag |

### Per-file extraction table (with Extract-vs-Inline rationale per D24)

#### File 1 — `mollie_checkout_screen.dart` (248 → ~140 LOC) · PR-A · CRITICAL
| New artefact | Path | Type | Extract rationale |
|--------------|------|------|-------------------|
| `MollieCheckoutLoadingOverlay` | `transaction/presentation/widgets/mollie_checkout_loading_overlay.dart` | StatelessWidget | 30 LOC + Semantics liveRegion testable in isolation |
| `MollieCheckoutErrorView` | `transaction/presentation/widgets/mollie_checkout_error_view.dart` | StatelessWidget (callbacks `onRetry`, `onCancel`) | 50 LOC + 2 callbacks + 5 testable behaviours (icon, title, body, retry tap, cancel tap) |
| `MollieUrlValidator` (pure) | `transaction/domain/mollie_url_validator.dart` | Pure Dart class | Independent reuse: payment listener, deep-link handler, future Apple Pay flow |
| `MollieCheckoutBodyFrame` | (already public, untouched) | StatelessWidget | — |
> **Keep in screen:** `WebViewController` + lifecycle + `setState` flag (line 14 doc respected).

#### File 2 — `chat_thread_screen.dart` (228 → ~140 LOC) · PR-B · HIGH
| New artefact | Path | Type | Extract rationale |
|--------------|------|------|-------------------|
| `ChatThreadBody` | `messages/presentation/widgets/chat_thread_body.dart` | StatelessWidget | 50 LOC + 4 props + structural pinning testable |
| `ChatScamAlertSlot` | `messages/presentation/widgets/chat_scam_alert_slot.dart` | ConsumerWidget (D2 exception — needs `scamAlertDismissedProvider`) | 25 LOC but 4 testable behaviours (none / low / medium / high confidence variants) |
> **Keep in screen:** `ScrollController`, `_isNearBottom`, `_scrollToBottom`, `ref.listen` auto-scroll, 3 `_handle*` methods.

#### File 3 — `category_detail_screen.dart` (228 → ~70 LOC) · PR-C · LOW
| New artefact | Path | Type | Extract rationale |
|--------------|------|------|-------------------|
| `CategoryDetailDataView` | `home/presentation/widgets/category_detail_data_view.dart` | StatelessWidget | Already in-file as `_DataView`; 60 LOC + 3 sub-sections |
| `CategorySubcategoryChips` | `home/presentation/widgets/category_subcategory_chips.dart` | StatelessWidget | 40 LOC + chip-tap callback + 3 states (empty / single / multi) |
| `CategoryFeaturedListingCard` | `home/presentation/widgets/category_featured_listing_card.dart` | StatelessWidget | 35 LOC + tap callback + price formatting testable |
> **Inline:** `_heroSection`, `_featuredHeader` — each <15 LOC, zero callbacks (D11 inline threshold).

#### File 4 — `detail_loading_view.dart` (225 → ~80 LOC) · PR-D2 · LOW
| New artefact | Path | Type | Extract rationale |
|--------------|------|------|-------------------|
| `SkeletonBone` (NEW shared) | `lib/widgets/feedback/skeleton_bone.dart` | StatelessWidget — `width`, `height`, `radius` | **In PR-D1, not PR-D2.** Independent reuse: 5+ future skeleton screens. |
> **Inline:** Replace `_bone()` helper + 5 skeleton wrapper classes with `SkeletonBone` calls. Net file delete: 0; consolidation only (D11 — false-positive extraction avoided).

#### File 5 — `search_results_view.dart` (225 → ~80 LOC) · PR-E · MED
| New artefact | Path | Type | Extract rationale |
|--------------|------|------|-------------------|
| `SearchResultsExpanded` | `search/presentation/widgets/search_results_expanded.dart` | StatelessWidget | 70 LOC + responsive layout pinning needs golden test |
| `SearchResultsCompact` | `search/presentation/widgets/search_results_compact.dart` | StatelessWidget | 60 LOC + responsive layout pinning needs golden test |
> **Inline:** `_loadMoreSpinner` (8 LOC), grid trivia.

#### File 6 — `home_data_view.dart` (209 → ~90 LOC) · PR-C · LOW
| New artefact | Path | Type | Extract rationale |
|--------------|------|------|-------------------|
| `HomeNearbySection` | `home/presentation/widgets/home_nearby_section.dart` | StatelessWidget | 35 LOC + 3 testable behaviours (empty / grid / nav callback) |
| `HomeRecentSection` | `home/presentation/widgets/home_recent_section.dart` | StatelessWidget | 30 LOC + horizontal-scroll behaviour pinning |
> **Keep:** `_BuyerAppBarActions` (private, file-local, 18 LOC, 0 callbacks — appropriate). **Inline:** `_trustBanner` (12 LOC, 0 callbacks), `_categories` (15 LOC, 0 callbacks).

#### File 7 — `listing_detail_screen.dart` (205 → ~80 LOC) · PR-D2 · MED
| New artefact | Path | Type | Extract rationale |
|--------------|------|------|-------------------|
| `ListingDetailDataView` | `listing_detail/presentation/widgets/listing_detail_data_view.dart` | StatelessWidget | Already in-file `_DataView`; 70 LOC + responsive variant logic |
| `ListingDetailCompactLayout` | `listing_detail/presentation/widgets/listing_detail_compact_layout.dart` | StatelessWidget | 45 LOC + scroll integration pinning |
| `ListingDetailExpandedLayout` | `listing_detail/presentation/widgets/listing_detail_expanded_layout.dart` | StatelessWidget | 50 LOC + 2-pane responsive layout |
| `ListingDetailActions` | `listing_detail/presentation/listing_detail_actions.dart` | Plain Dart class | 40 LOC + share/clipboard side effects + 4 testable behaviours |

#### File 8 — `appeal_screen.dart` (205 → ~120 LOC) · PR-F2 · MED
| New artefact | Path | Type | Extract rationale |
|--------------|------|------|-------------------|
| `AppealAppBar` | `profile/presentation/widgets/appeal_app_bar.dart` | StatelessWidget | 25 LOC + 2 callbacks (back, save) |
| `DiscardChangesDialog` (NEW shared) | `lib/widgets/dialogs/discard_changes_dialog.dart` | StatelessWidget | **In PR-F1, not PR-F2.** Independent reuse: appeal + listing_creation + future edit flows |
| `appealBodyProvider` | `profile/presentation/viewmodels/appeal_body_provider.dart` | Riverpod provider | 20 LOC; provider stays in viewmodel layer per §1 |

#### File 9 — `listing_creation_screen.dart` (204 → ~110 LOC) · PR-G · LOW (depends on PR-F1)
| New artefact | Path | Type | Extract rationale |
|--------------|------|------|-------------------|
| `ListingCreationStepBody` | `sell/presentation/widgets/listing_creation_step_body.dart` | StatelessWidget | 50 LOC + 4-step switch + step-indicator + 4 testable variants |
| `ListingCreationLeading` | `sell/presentation/widgets/listing_creation_leading.dart` | StatelessWidget | 30 LOC + 4-step switch (back/discard/none variants) |
| `ListingDiscardDialog` | (no new file) | — | Consumes `DiscardChangesDialog` from PR-F1; in-screen helper deleted |

---

## 3.5. Forbidden Modifications During P-54 (per D17 / C4)

> **Tier-1 Anti-pattern guard:** "Incidental changes" during refactors silently break consumers, animations, or screen-reader behaviour. The following modifications are **forbidden** in any P-54 PR — if any are necessary, raise a separate ticket and do not bundle them in.

❌ **Existing public widget rename** (would break consumers + golden coverage map)
❌ **`Key` assignment changes** on `AnimatedSwitcher` / `Hero` / `ListView` item children (animation regression)
❌ **`const` ↔ non-`const` constructor flips** on rebuild-sensitive widgets (element identity break)
❌ **Public method signature changes** on `Notifier` / `Repository` interfaces (consumer break)
❌ **l10n key rename or removal** (translation drift)
❌ **Theme token swap** — `DeelmarktColors` / `Spacing` / `DeelmarktTypography` / `DeelmarktRadius` (design-system drift)
❌ **Adding/removing `RepaintBoundary` or `KeyedSubtree`** (raster boundary changes — pixel-equivalent but anti-aliasing-different)
❌ **`IndexedStack` / `Offstage` index ordering changes** (state preservation break)

If a forbidden modification appears necessary, raise a separate ticket linked to this plan. Reviewers reject any P-54 PR that contains any of the above.

---

## 4. Shared primitives (decision D4 + isolation per H2/D21)

### `SkeletonBone` (NEW) — ships in PR-D1 (standalone)
- **Path:** `lib/widgets/feedback/skeleton_bone.dart`
- **API:** `SkeletonBone({required double width, required double height, double radius = 4})`
- **Reason:** detail_loading_view's bespoke `_bone()` helper is a §3.3 (DRY) violation; future skeleton work needs the same primitive.
- **Test:** `test/widgets/feedback/skeleton_bone_test.dart` — render + golden (light/dark) + a11y (no Semantics needed; decorative — explicit `excludeFromSemantics: true`).
- **Kill switch (M2):** Unleash flag `skeleton_bone_enabled` (default `true`); emergency disable falls back to `Container` filler. Migration path documented in primitive's docstring.

### `DiscardChangesDialog` (NEW) — ships in PR-F1 (standalone)
- **Path:** `lib/widgets/dialogs/discard_changes_dialog.dart`
- **API:** `DiscardChangesDialog.show(context, {required String titleKey, required String messageKey, required String confirmLabelKey, String? cancelLabelKey}) → Future<bool>`
- **Reason:** identical pattern in `appeal_screen` and `listing_creation_screen`; `lib/features/sell/edit/` will need it next sprint.
- **Test:** `test/widgets/dialogs/discard_changes_dialog_test.dart` — render + tap-confirm (returns true) + tap-cancel (returns false) + barrier-dismissed (returns false) + Semantics labels present + l10n keys resolved.
- **Kill switch (M2):** Unleash flag `discard_dialog_enabled`; emergency falls back to a native `AlertDialog` constructed from the **same l10n keys** (`titleKey.tr()` / `messageKey.tr()` / `confirmLabelKey.tr()`) so the fallback path stays localised. The fallback drops only the design-system colour token (destructive button takes the platform default red) — acceptable for an emergency code path, since the flag would only flip if the styled implementation crashes.

---

## 5. Refactor protocol per risk tier

### CRITICAL (mollie_checkout) — 7-step protocol
1. **Audit existing tests** under `test/features/transaction/`. If coverage of trusted-host validator + redirect detector + retry path + cancel path < 100%, write characterisation tests against current shape.
2. **Capture P-56 baseline** — Firebase Performance dashboard screenshot of `payment_create` p50/p95/p99 trace over 7 days. Commit to PR description as evidence.
3. **Extract pure logic upward** — move `_trustedHosts` + URL trust check to `transaction/domain/mollie_url_validator.dart`. 100% unit-testable.
4. **Refactor pass A:** extract `MollieCheckoutErrorView` (relocation only, `_retry` callback wired through `VoidCallback`). Run characterisation suite.
5. **Refactor pass B:** extract `MollieCheckoutLoadingOverlay`. Run characterisation suite + goldens + screenshot drivers.
6. **Feature-flag wrap (D15/C1):** create Unleash flag `mollie_checkout_v2`; new code path runs only when flag = `true`; old monolith preserved when `false`. Default `false` at merge.
7. **Rollout:**
   - T+0: merge → flag default `false` (no user impact)
   - T+24h: enable on staging; complete 5 sandbox iDEAL transactions (success / cancel / network-fail / timeout / 3DS-challenge); verify Sentry breadcrumb chain unchanged
   - T+48h: production rollout to **5%** of users; monitor `payment_create` p95 + Sentry error rate (no >5% delta)
   - T+1w: rollout to **100%** (gradual: 5% → 25% → 50% → 100% over 7d)
   - T+2w: remove flag + delete legacy code path (separate small PR)

### HIGH (chat_thread) — 4-step protocol
1. **Pre-PR:** PR-A1 lands a fix for #203 (separate scope). Un-skip `chat_thread_screenshot_test.dart`. Prove stable across 3 CI runs.
2. **Capture P-56 baseline** — `chat_open` trace if present, or proxy via cold-`listing_load` then chat-open user flow. Document in PR-B description.
3. Extract only the **declarative Column body** as `ChatThreadBody` + `ChatScamAlertSlot`.
4. Regenerate goldens **with manual visual diff review** on dark-mode + LTR + 360-px variant minimum, **5% pixel tolerance** (D14/M6) for anti-aliasing noise; >5% = manual review.

### MED (4 files: search, appeal, listing_detail, listing_creation)
1. Identify extraction seams per §3 table.
2. Extract one widget per commit, co-commit its test.
3. Run `flutter test test/features/<feature>/` after each commit.
4. Run `flutter test --update-goldens` on a throwaway branch first; review byte-diff before accepting.

### LOW (3 files: category_detail, home_data_view, detail_loading_view)
1. Extract per §3 table; co-commit tests.
2. Run feature test + golden suite. Land.

---

## 6. PR sequencing (10 PRs total — H2 isolation applied)

> **Reviewer SLA (D20/H1):** First review **24h**, revisions **12h**. Blocked dependencies (e.g. PR-G→PR-F2) escalate to mahmutkaya at **T+48h**.
> **Hotfix lane (D23/H4 — Level 0):** Production regression after merge → `hotfix/<scope>` branch + 30-min reviewer SLA + cherry-pick to `dev` + `main`. Distinct from revert.

| PR | Title | Files | Depends on | Effort | Reviewer(s) |
|----|-------|-------|-----------|--------|-------------|
| **A1** | `fix(messages): resolve chat_thread golden pre-paint capture (#203)` | `chat_thread_screenshot_test.dart` (un-skip) + minimal source | — | S (½ d) | mahmutkaya |
| **D1** ✨ | `feat(widgets): add SkeletonBone shared primitive (P-54)` | `lib/widgets/feedback/skeleton_bone.dart` + test | — | S (½ d) | reso (architecture) |
| **F1** ✨ | `feat(widgets): add DiscardChangesDialog shared primitive (P-54)` | `lib/widgets/dialogs/discard_changes_dialog.dart` + test | — | S (½ d) | reso |
| **C** | `refactor(home): decompose category_detail + home_data_view (P-54)` | files 3 + 6 | — | S (1 d) | mahmutkaya |
| **D2** | `refactor(listing_detail): decompose detail screen + skeletons (P-54)` | files 4 + 7 | **PR-D1** | M (1.5 d) | mahmutkaya |
| **E** | `refactor(search): decompose search_results_view (P-54)` | file 5 | — | S (1 d) | mahmutkaya |
| **F2** | `refactor(profile): decompose appeal_screen (P-54)` | file 8 | **PR-F1** | M (1.5 d) | mahmutkaya |
| **G** | `refactor(sell): decompose listing_creation (P-54)` | file 9 | **PR-F1** | M (1 d) | mahmutkaya |
| **B** | `refactor(messages): decompose chat_thread_screen (P-54)` | file 2 | **PR-A1** | M (1 d) | mahmutkaya |
| **A** | `refactor(transaction): decompose mollie_checkout — payment-critical (P-54)` | file 1 + extracted domain | — | M (2 d) + 2 w rollout window | belengaz primary + reso architecture |

> **Total calendar (D24/C3):** **3–4 weeks** = 1.5 weeks active development + reviewer cycles + 2 weeks Mollie rollout window. **PR cadence:** 1 LOW/MED PR/day max; 1 HIGH PR every 2 days; mollie standalone week.
>
> **Branch convention (CLAUDE.md §5.2):** `feature/pizmam-audit-P54-<scope>` — e.g. `feature/pizmam-audit-P54-home`, `feature/pizmam-audit-P54-skeleton-bone`, `feature/pizmam-audit-P54-mollie`.

---

## 7. Mandatory rule consultation

| Rule | Applicable? | How addressed |
|------|-------------|---------------|
| §1.2 Layer dependency | **Yes** | Extracted widgets stay in `presentation/widgets/`; pure logic moves to `domain/` (mollie URL validator only) |
| §2.1 File length | **PRIMARY MOTIVATION** | Every artefact ≤ §2.1 budget per type |
| §2.2 Naming | **Yes** | D3 standardises Public PascalCase for own-file widgets |
| §3.1 Shared widgets | **Yes** | D4 introduces 2 primitives to `lib/widgets/` (≥2 future call sites) |
| §3.3 No duplication | **Yes** | `_bone()` helper de-duplicated; identical discard dialogs de-duplicated |
| §4 Design system | **Yes** | All extractions preserve token usage; §3.5 forbids token swap |
| §6.1 Coverage | **Yes** | 80% on changed lines; **100% on payment path** (DoD #6a-d) |
| §6.2 Test layer matrix | **Yes** | New shared widgets get widget tests; feature widgets follow D7 |
| §6.3 Mocking | **Yes** | D8: `ProviderScope.overrides` + `Fake` repos |
| §7.5 UI tasks | **Yes** | Each extracted screen `/// Reference: docs/screens/...` |
| §8 Quality Gates | **Yes** | Pre-commit + pre-push hooks; check_quality.dart strict |
| §10 Accessibility | **Yes — critical** | D16/C2 introduces `check_a11y.dart` + manual VO/TalkBack on PR-A/B |
| §13 Marketing assets | No | — |

### `/quality-gate` Ethics & Safety Pass

| Domain | Result |
|--------|--------|
| **AI Bias** | N/A — pure refactor |
| **GDPR / Privacy** | N/A — no data flow change. PR-A explicitly verifies Sentry breadcrumb chain (data lineage preserved). |
| **Automation Safety** | ⚠️ Risk: silent semantic loss (e.g. `liveRegion: true` dropped). **Mitigation:** D7 mandatory Semantics test + D16 a11y automation. |
| **User Autonomy** | N/A |
| **Human-in-the-Loop** | ✅ All decompositions reviewed by human; PR-A + PR-B require explicit reviewer sign-off (D20). |

**Ethics verdict: ✅ APPROVED.**

### Competitive market reference

| Tier-1 reference | Practice | Applied here |
|------------------|----------|--------------|
| Stripe (checkout WebView) | Characterisation + feature-flag rollout | mollie protocol §5 + D15 |
| Linear (React component conventions) | One file per public widget; PascalCase | D3 + §3 table |
| Apple SwiftUI | Parent has no children manifest | D12 |
| Vinted (Flutter marketplace) | StatelessWidget extraction with prop-passing default | D2 |
| Google Web Vitals + RAIL | p95 latency budget enforcement | D19 + perf budget |
| Material 3 / Apple HIG | Reject `BottomActionBar` shared primitive | §4 negative decision |

**Differentiation:** combined 100%-payment-coverage + Semantics-test-on-interactive-extract + 5%-pixel-tolerance-with-manual-review + Unleash-feature-flag-rollout exceeds any documented Vinted / Wallapop public practice.

---

## 8. Implementation tasks (per PR)

### PR-A1 — Fix #203 chat_thread golden (½ day)
- [ ] Investigate pre-paint capture issue (likely `addPostFrameCallback` racing test harness)
- [ ] Apply minimal source/test change to stabilise
- [ ] Un-skip `chat_thread_screenshot_test.dart`
- [ ] Verify 3 consecutive green CI runs
- [ ] PR description includes `_TBD pre-paint capture race resolution: <root cause>` block
- [ ] Land

### PR-D1 — `SkeletonBone` shared primitive (½ day)
- [ ] Create `lib/widgets/feedback/skeleton_bone.dart` (≤30 LOC)
- [ ] Test: `test/widgets/feedback/skeleton_bone_test.dart` — render, golden light/dark (M3: nl-NL + en-US), `excludeFromSemantics: true` assert
- [ ] Add Unleash flag `skeleton_bone_enabled` (default `true`) (M2)
- [ ] CHANGELOG entry
- [ ] reso architecture review

### PR-F1 — `DiscardChangesDialog` shared primitive (½ day)
- [ ] Create `lib/widgets/dialogs/discard_changes_dialog.dart` (≤80 LOC)
- [ ] Test: 4 cases (confirm / cancel / barrier-dismissed / Semantics labels) + l10n key resolution
- [ ] Add Unleash flag `discard_dialog_enabled` (default `true`) (M2)
- [ ] l10n keys added: `dialog.discard.title`, `dialog.discard.message`, `dialog.discard.confirm`, `dialog.discard.cancel` in both `en-US.json` + `nl-NL.json`
- [ ] CHANGELOG entry
- [ ] reso architecture review

### PR-C — Home decomposition (1 day)
- [ ] Extract `CategoryDetailDataView`, `CategorySubcategoryChips`, `CategoryFeaturedListingCard`
- [ ] Extract `HomeNearbySection`, `HomeRecentSection`
- [ ] Inline `_trustBanner`, `_categories`, `_heroSection`, `_featuredHeader` per D11
- [ ] Co-commit 5 widget tests (smoke + Semantics + interaction; goldens for visually distinctive)
- [ ] Verify both files ≤ 200 LOC; goldens ≤ 5% pixel diff (D14/M6)
- [ ] Run `dart run scripts/check_a11y.dart` (D16/C2)

### PR-D2 — Listing-detail (1.5 days, depends on PR-D1)
- [ ] Rebase on `dev` after PR-D1
- [ ] Replace `_bone()` + 5 skeleton classes in `detail_loading_view.dart` with `SkeletonBone`
- [ ] Extract `ListingDetailDataView`, `ListingDetailCompactLayout`, `ListingDetailExpandedLayout`
- [ ] Extract `ListingDetailActions` (controller for share/clipboard)
- [ ] Co-commit 5 widget tests + 1 controller test
- [ ] Verify both files ≤ 200 LOC; goldens ≤ 5% pixel diff
- [ ] DevTools memory snapshot pre/post (M1) — committed as PR comment

### PR-E — Search decomposition (1 day)
- [ ] Extract `SearchResultsExpanded`, `SearchResultsCompact`
- [ ] Inline `_loadMoreSpinner` + grid trivia
- [ ] Co-commit 2 widget tests covering responsive variants (compact + expanded) × 2 locales (M3)
- [ ] Verify file ≤ 200 LOC

### PR-F2 — Appeal decomposition (1.5 days, depends on PR-F1)
- [ ] Rebase on `dev` after PR-F1
- [ ] Migrate `appeal_screen.dart` to consume `DiscardChangesDialog`
- [ ] Extract `AppealAppBar`
- [ ] Move `_AppealBody` provider to `viewmodels/appeal_body_provider.dart`
- [ ] Co-commit widget tests
- [ ] Verify file ≤ 200 LOC

### PR-G — Listing-creation (1 day, depends on PR-F1)
- [ ] Rebase on `dev` after PR-F1
- [ ] Extract `ListingCreationStepBody`, `ListingCreationLeading`
- [ ] Migrate inline discard dialog to `DiscardChangesDialog`
- [ ] Co-commit widget tests
- [ ] Verify file ≤ 200 LOC

### PR-B — Chat-thread decomposition (1 day, depends on PR-A1)
- [ ] Rebase on `dev` after PR-A1
- [ ] Capture P-56 baseline (D19/C6) — `chat_open` proxy trace
- [ ] Extract `ChatThreadBody` (StatelessWidget) — ScrollController stays in screen
- [ ] Extract `ChatScamAlertSlot` (ConsumerWidget — D2 exception)
- [ ] Co-commit 2 widget tests (4 scam-confidence variants + structural pinning)
- [ ] `flutter test --update-goldens` on throwaway branch; manual visual diff on dark + LTR + 360px (D14/M6)
- [ ] Test on canvasKit + html web renderers (M5)
- [ ] DevTools memory snapshot pre/post (M1) — long-lived screen
- [ ] Manual VoiceOver/TalkBack test recorded as PR comment (D16/C2)
- [ ] T+48h post-merge p95 comparison; >10% regression = revert (D19/C6)
- [ ] Verify file ≤ 200 LOC

### PR-A — Mollie checkout decomposition (2 days dev + 2 weeks rollout)
- [ ] **Step 1:** audit existing payment-test coverage; write characterisation tests if < 100%
- [ ] **Step 2:** capture P-56 `payment_create` baseline — 7-day p95 dashboard screenshot in PR description (D19/C6)
- [ ] **Step 3:** extract `MollieUrlValidator` to `transaction/domain/`; 100% unit test
- [ ] **Step 4 (pass A):** extract `MollieCheckoutErrorView`; run characterisation suite
- [ ] **Step 5 (pass B):** extract `MollieCheckoutLoadingOverlay`; run characterisation suite + goldens
- [ ] **Step 6:** wrap in Unleash flag `mollie_checkout_v2` (default `false`) (D15/C1)
- [ ] **Step 7:** manual sandbox iDEAL transaction set on staging (5 cases); verify Sentry breadcrumb chain
- [ ] Manual VoiceOver test on iOS recorded as PR comment (D16)
- [ ] Test on canvasKit + html (M5)
- [ ] Co-reviewer: belengaz primary + reso architecture (D20/H1)
- [ ] **Rollout sequence:** T+24h staging → T+48h 5% prod → T+1w 100% (5%→25%→50%→100% gradient over 7d) → T+2w flag removal
- [ ] **Acceptance:** `payment_create` p95 +0% ±100ms tolerance (D19/C6)
- [ ] Verify file ≤ 200 LOC

---

## 9. Cross-cutting concerns (expanded for v2 amendments)

### Security / Privacy
- ✅ No data-flow change in any extraction
- ✅ Mollie URL validator extraction strengthens trust-host check (becomes pure-logic, fully testable)
- ✅ Sentry breadcrumb chain explicitly verified in PR-A step 7
- ✅ No new attack surface
- ✅ Feature-flag rollout (D15/C1) reduces blast radius for payment regression

### Testing — layered coverage targets (D18/C5)
| Layer | Target | Enforcement |
|-------|-------:|-------------|
| **Domain** (pure Dart classes — `MollieUrlValidator`) | **100%** | `check_new_code_coverage.dart` strict mode |
| **Data** (repositories with `Fake<>` overrides) | **≥80%** | `check_new_code_coverage.dart` |
| **Presentation stateful** (Notifier / StatefulWidget) | **≥80%** | `check_new_code_coverage.dart` |
| **Presentation pure UI** (StatelessWidget) | **≥60%** | smoke + Semantics + 1 interaction sufficient (D7) |
| **Payment path** (override) | **100%** | CLAUDE.md §6.1 |

### Documentation
- Each extracted widget: `///` doc with screen-spec ref + intentional-deviation notes
- ADR not required (refactor preserves existing seam) — but ADR-028 amendment to §2.2 (D3 naming) recommended as follow-up
- CHANGELOG entry per PR
- `docs/SCREENS-INVENTORY.md`'s "§2.1 budget breach" warnings → cleared as files drop below 200 LOC
- **L2:** `docs/RETRO-P54.md` retrospective written at burn-down completion (lessons learned feedback loop)

### Accessibility (D16/C2 — expanded)
- **Automated (PR gates):**
  - `dart run scripts/check_a11y.dart` — 4.5:1 contrast, 44px touch target, Semantics tree integrity
  - SemanticsTester assertions in every interactive widget test (D7)
  - Focus order pinning test (Tab traversal) for forms (PR-F2 appeal, PR-A mollie error view)
- **Manual (PR-A + PR-B):**
  - VoiceOver (iOS) + TalkBack (Android) walkthrough recorded as PR comment with timestamps
  - Keyboard-only navigation: every interactive element reachable via Tab/Enter
- **Forbidden** (per §3.5): silent removal of `liveRegion`, `excludeSemantics`, `Semantics` labels

### Localisation (M3 — expanded)
- All `.tr()` keys preserved verbatim; no l10n changes (forbidden per §3.5)
- **Goldens captured in BOTH `nl-NL` + `en-US`** locales per PR (M3) — Dutch typography reveals layout issues English masks
- New l10n keys (PR-F1 dialog) added to both locale files in same commit

### Performance (D19/C6 — expanded)
- **Baseline:** capture P-56 trace p50/p95/p99 over 7 days BEFORE PR opens (mandatory for PR-A, PR-B; recommended for PR-D2)
- **Acceptance:** `payment_create` (PR-A) — **p95 +0% ±100ms**. All other traces — **p95 ≤ +10%**.
- **Monitoring:** T+48h post-merge dashboard comparison. **Revert trigger:** the rolling 24-hour median of `payment_create` (and any other touched trace) p95 is >10% above the pre-merge 7-day baseline median, sustained across at least two consecutive 24-hour windows. A single noisy CI run does not trigger revert. Action level: hotfix (§11 Level 0) for a single trace; git-revert (§11 Level 4) for a multi-trace regression.
- **No new `RepaintBoundary` / `Builder` / `LayoutBuilder` introductions** (forbidden per §3.5)

### Observability
- Existing P-56 traces preserved verbatim; no rename, no boundary shift
- **L3:** ProviderObserver instrumentation (optional) — capture state-change rate baseline pre/post; useful diagnostic if regression suspected post-merge

### CI cost (H3/D22)
- **Pre-amendment baseline:** ~12m29s flutter_test
- **Post-amendment expectation:** +60-90s per PR with default concurrency; **+30s with `--concurrency=4`**
- **Mitigation:** add `--concurrency=4` to `.github/workflows/ci.yml` flutter_test step
- **Per-PR runtime budget:** +60s; aşılırsa test split into separate file or batch

### Memory profiling (M1)
- **Required for:** PR-B (chat_thread — long-lived screen), PR-D2 (listing_detail — many gallery items)
- **Method:** DevTools Memory tab — heap snapshot before refactor + same scenario after refactor; commit screenshot pair as PR comment
- **Acceptance:** allocated heap delta ≤ +5% on identical scenario

### Mobile vs web renderer (M5)
- **PR-A (mollie) + PR-B (chat):** test under both `--web-renderer canvaskit` and `--web-renderer html`
- **Other PRs:** default web renderer sufficient
- **Reasoning:** different rebuild semantics on web; mollie WebView + chat scroll behaviour are platform-channel + scroll-physics sensitive

### Hotfix protocol — Level 0 (D23/H4)
- Production regression detected post-merge → branch `hotfix/<scope>` from `main`
- 30-min reviewer SLA (mahmutkaya or designated on-call)
- Cherry-pick to `dev` immediately after `main` lands
- Distinct from revert paths (use when revert is dangerous — e.g. database migration already applied, or feature flag mid-rollout)

---

## 10. Risk matrix (expanded)

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|-----------|--------|-----------|
| **R1** | Mollie payment regression | Low | **CRITICAL (money loss)** | Characterisation tests + URL validator unit tests + sandbox iDEAL set + Unleash flag rollout (D15) + co-review by belengaz |
| **R2** | chat_thread golden destabilisation | Medium | High | PR-A1 fixes #203 first; manual visual diff on dark/LTR/360px with 5% pixel tolerance |
| **R3** | Semantics label silently dropped | Medium | High (a11y regression) | D16 `check_a11y.dart` + Semantics test mandatory + manual VO/TalkBack on PR-A/B |
| **R4** | Coverage gate false-fail | Medium | Medium | D13 co-commit + per-layer DoD (D18) |
| **R5** | Goldens diverge on layout-equivalent extraction | Low | Medium | §3.5 forbids new `Builder`/`LayoutBuilder`/`RepaintBoundary`; 5% pixel tolerance |
| **R6** | PR-G blocked on PR-F1/F2 merge delay | Medium | Low | D20 reviewer SLA + escalation matrix |
| **R7** | PR-B blocked on PR-A1 #203 fix | Low | Medium | PR-A1 isolated + small (½ day expected) |
| **R8** | Conflict surface with concurrent sprint work | Medium | Medium | Per-feature PR scope; D11 forbids cross-cutting changes |
| **R9** | False-positive extraction (over-engineering) | Low | Low | D11 thresholds + per-file rationale (H5/D24) + reviewer enforcement |
| **R10** | Test file >300 LOC (D10 violation) | Low | Low | D10 strict — one test file per widget |
| **R11** | Extracted widget API drift (params reordered) | Low | Low | Constructor params named (Dart convention); no positional args >2 |
| **R12** | Premature `lib/widgets/` promotion | Low | Low | D4 limited to 2 primitives with verified ≥2 call-site reuse |
| **R13** ✨ | **Performance regression vs P-56 baseline** | Medium | High | D19/C6 budget; T+48h dashboard comparison; >10% = revert |
| **R14** ✨ | **Memory regression in long-lived screens** | Low | Medium | M1 DevTools snapshot pre/post on PR-B + PR-D2; +5% delta cap |
| **R15** ✨ | **CI runtime regression** | Medium | Low | D22/H3 `--concurrency=4`; per-PR +60s budget |
| **R16** ✨ | **Locale-specific layout issue masked by EN-only goldens** | Low | Medium | M3 — both `nl-NL` + `en-US` goldens captured |
| **R17** ✨ | **Web renderer-specific regression (canvasKit vs html)** | Low | Medium | M5 dual-renderer test on PR-A + PR-B |
| **R18** ✨ | **Forbidden modification accidentally lands** | Low | High | §3.5 reviewer rejection criterion explicit |
| **R19** ✨ | **Reviewer bottleneck stalls calendar** | High | Medium | D20 SLA + escalation; H6 PR template reduces review time |
| **R20** ✨ | **Shared primitive bug blasts all consumers** | Low | High | H2 isolation: PR-D1 + PR-F1 ship FIRST + pass independently before consumer PRs rebase |
| **R21** ✨ | **Mollie rollout flag forgotten / left on `false`** | Medium | Medium | D15 explicit T+2w cleanup PR; calendar reminder |

---

## 11. Multi-level rollback (expanded — Level 0 added)

| Level | Action | Effect | When |
|-------|--------|--------|------|
| **L0** ✨ | Forward-fix hotfix (`hotfix/<scope>` branch, 30-min SLA) | Targeted fix without revert | DB migration applied / feature-flag mid-rollout / revert dangerous |
| **L1** | Per-commit revert (`git revert <commit-sha>`) | Single screen returns to pre-P54 shape | Single-extraction regression |
| **L2** | Per-PR revert (`git revert -m 1 <merge-sha>`) | One feature folder restored | Single-PR regression |
| **L3** | PR-A emergency: flip Unleash `mollie_checkout_v2` to `false` | Old monolith path active; no code revert | **Mollie regression — preferred over revert** thanks to D15 |
| **L4** | Shared primitive revert (PR-D1 / PR-F1) — flip Unleash `*_enabled` to `false` | Consumers fall back to inline pattern | M2 kill switch |
| **L5** | Full series revert (sequence of L2 reverts in reverse merge order) | Dev tree returns to pre-P54 state | Last-resort full rollback |

> **Rollback eligibility:** L0–L4 are unconditional and non-destructive; L5 is last-resort.
> **Rollback decision tree:** active flag rollout → L3 (flip) > L2 (revert) > L1 (per-commit). Migration in flight → L0 (forward-fix).

---

## 12. Quality gate checklist (per PR)

| Gate | Owner | Evidence |
|------|-------|---------|
| `flutter analyze --fatal-infos` zero issues | pizmam | CI |
| `flutter test --concurrency=4` zero failures | pizmam | CI |
| Coverage targets per layer (DoD #6a–6d) | pizmam | `check_new_code_coverage.dart` pre-push |
| Coverage 100% on payment path (PR-A only) | pizmam + belengaz | CLAUDE.md §6.1 |
| `dart run scripts/check_quality.dart --all` zero violations | pizmam | CI |
| `dart run scripts/check_a11y.dart` zero violations | pizmam | CI (new) |
| Goldens byte-identical OR ≤5% pixel diff with manual review | pizmam | `git diff --stat test/screenshots/` + visual review comment |
| Goldens captured in both `nl-NL` + `en-US` (M3) | pizmam | golden filename audit |
| Each extracted widget has matching test file | pizmam | path audit |
| Each interactive widget has Semantics + a11y assertions | pizmam | grep tests |
| Touch targets ≥44×44px preserved | pizmam | a11y script |
| `dart format` + pre-commit hooks pass | pizmam | Auto |
| §3.5 forbidden modifications none (reviewer audit) | reviewer | PR description checklist |
| **PR-A only:** Unleash flag exists; rollout sequence documented | pizmam + belengaz | PR description |
| **PR-A only:** Sandbox iDEAL transaction set complete (5 cases) | pizmam + belengaz | Recorded in PR comment |
| **PR-A only:** P-56 baseline + post-merge comparison | pizmam | Dashboard screenshot |
| **PR-A + PR-B:** Manual VoiceOver / TalkBack pass | pizmam | Recorded video / transcript in PR comment |
| **PR-A + PR-B:** Mobile + web renderer tested | pizmam | CI matrix |
| **PR-B + PR-D2:** DevTools memory snapshot pre/post | pizmam | Screenshot pair in PR comment |
| Reviewer approval (D20 SLA) | mahmutkaya / belengaz / reso | GitHub PR |

---

## 13. Definition of Done (numerical bar — v2 expanded)

P-54 is complete if and only if **all 17 thresholds** below hold:

1. ✅ `flutter analyze --fatal-infos` — zero warnings
2. ✅ All 9 target files ≤ **200 LOC** (CLAUDE.md §2.1)
3. ✅ All extracted sub-widget files ≤ **200 LOC** each
4. ✅ All new test files ≤ **300 LOC** each
5. ✅ `flutter test --concurrency=4` — 100% pass, **zero new `skip:true`**
6. **Coverage by layer (D18/C5):**
   - 6a. Domain layer: **100%** on changed lines
   - 6b. Data layer: **≥80%**
   - 6c. Presentation stateful: **≥80%**
   - 6d. Presentation pure UI: **≥60%**
   - 6e. Payment path override: **100%** on `mollie_checkout_screen.dart` + `MollieUrlValidator` + extracted children
7. ✅ Golden suite: byte-identical OR ≤5% pixel diff with manual review note (D14/M6)
8. ✅ `chat_thread_screenshot_test.dart` un-skipped and passing OR still skipped *with same `#203` annotation* (no silent re-skip)
9. ✅ Each commit individually green under `flutter test` (bisect-safe — D9)
10. ✅ `check_quality.dart --all` — zero violations introduced
11. ✅ `check_a11y.dart` — zero violations introduced (D16/C2)
12. ✅ Ten PRs (1 prep + 7 feature + 2 primitive isolation), each with reviewer SLA met
13. ✨ Mollie Unleash flag exists; rollout sequence executed without rollback (D15/C1)
14. ✨ P-56 trace p95 regression ≤ 10% on all traces; `payment_create` ≤ +0% ±100ms (D19/C6)
15. ✨ Manual VoiceOver / TalkBack pass on PR-A + PR-B (D16/C2)
16. ✨ Memory regression ≤ +5% on PR-B + PR-D2 scenarios (M1)
17. ✨ §3.5 forbidden modifications: zero introduced (reviewer audit per PR — C4)

If any of these seventeen fails, P-54 is not done.

---

## 14. Tooling artefacts (new for v2)

This plan ships supporting tooling alongside the refactor, committed in a one-off setup PR before burn-down begins:

| Artefact | Path | Purpose | Origin |
|----------|------|---------|--------|
| **PR description template** | `docs/templates/PR-P54-template.md` | Reviewer ergonomics; auto-populates DoD checklist | H6 |
| **Bisect runner** | `scripts/bisect_p54.sh` | `git bisect run`-compatible test wrapper | M4 |
| **A11y check script** | `scripts/check_a11y.dart` | 4.5:1 contrast + 44px touch + Semantics integrity | D16/C2 |
| **Memory profiling guide** | `docs/runbooks/memory-profiling.md` | DevTools snapshot procedure for PR-B + PR-D2 | M1 |
| **Retrospective template** | `docs/RETRO-P54.md` (created at burn-down end) | Lessons-learned feedback loop | L2 |
| **§2.2 amendment proposal** | `docs/adr/ADR-028-widget-naming.md` | Public PascalCase vs `_PascalCase` standardisation | D3 |
| **`check_quality.dart` extraction-suggestion lint** | `scripts/check_quality.dart` (extension) | Auto-suggest extraction for >30 LOC methods with callbacks | L4 |
| **Error boundary widget** | `lib/widgets/feedback/error_boundary.dart` | Sentry-tracked error boundary wrapper for extracted screens | L1 |

---

## 15. Sequencing note

> **Calendar (revised per C3):** **3–4 weeks** total = 1.5 weeks active development + reviewer cycles + 2 weeks Mollie rollout window.

**Parallelisable** (no dependency, can author concurrently):
- PR-A1 + PR-D1 + PR-F1 + PR-C + PR-E + PR-A (independent)

**Serial** (have dependencies):
- PR-D2 ← PR-D1
- PR-F2 ← PR-F1
- PR-G ← PR-F1
- PR-B ← PR-A1

**Reviewer load balancing:** mahmutkaya carries most reviews; reso reviews architecture-impact PRs (D1, F1, A); belengaz primary on payment-critical PR-A.

---

## 16. Provenance

- **Workflow:** `.agent/workflows/plan.md` v2.2.0 (Large track) + `/quality-gate` v2.1.0 (full Ethics & Safety pass — ✅ APPROVED) + Specialist Synthesis Protocol + Tier-1 Self-Audit
- **Specialist input received:**
  - **Architect (Opus 4.7)** — per-file extraction strategy, common patterns, payment refactor protocol, chat_thread golden risk, PR structure, test seam boundary, Riverpod boundary, naming convention, false-positive avoidance, documentation overhead
  - **TDD-guide (Opus 4.7)** — characterisation-test mandate, coverage delta defusal, golden-test detection protocol, #203 sequencing, per-widget test obligation, Riverpod test seam, mocking strategy, bisect commit granularity, test file organisation, CI cost analysis, anti-pattern catalogue, 11-point Definition of Done
- **Self-audit (v2):** 22 amendments applied — 6 CRITICAL (C1 feature flag, C2 a11y automation, C3 calendar revision, C4 forbidden modifications, C5 layered coverage, C6 perf budget), 6 HIGH (H1 SLA, H2 primitive isolation, H3 CI parallelism, H4 hotfix lane, H5 per-file rationale, H6 PR template), 6 MEDIUM (M1 memory, M2 kill switch, M3 i18n, M4 bisect script, M5 web renderer, M6 pixel tolerance), 4 LOW (L1 error boundary, L2 retrospective, L3 ProviderObserver, L4 lint extension)
- **Audit cross-references:** `docs/audits/2026-04-25-tier1-retrospective.md#p-54`, `docs/audits/2026-04-25-tier1-preflight.md` finding `M1`
- **Rule bases:** CLAUDE.md §1.2 / §2.1 / §2.2 / §3.1 / §3.3 / §4 / §6.1 / §6.2 / §6.3 / §7.5 / §8 / §10
- **Differentiation evidence:** competitor matrix — DeelMarkt's combined 100%-payment-coverage + Semantics-test-on-interactive-extract + Unleash-feature-flag-rollout + 5%-pixel-tolerance bar exceeds Vinted/Wallapop public practice
- **Companion plan:** P-55 (admin-widget decomposition) follows the same protocol on a smaller scope; can land before or after P-54 burn-down
