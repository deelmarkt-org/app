# PLAN-P54 — Decompose 9 over-budget screens (CLAUDE.md §2.1)

> **Owner:** 🔵 pizmam (`@emredursun`) · **Co-review on payment scope:** 🟢 belengaz (`@mahmutkaya`)
> **Severity / Audit ref:** P2 / `M1` (preflight) · `P-54` (retrospective)
> **Effort:** L — 1–2 weeks (8 PRs over the burn-down window)
> **Workflow:** `/plan` v2.2.0 + `/quality-gate` v2.1.0 + Specialist Synthesis Protocol
> **Task size:** **Large** (~25 new files across 7 feature folders + 2 shared primitives)
> **Created:** 2026-04-26 · Status: ⏳ Awaiting approval

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

§2.1 is not a style preference — it's a forcing function for cohesion that prevents the "200 files, can't find anything" anti-pattern Linear's engineering blog calls out as the single biggest cause of frontend velocity decay. Past §2.1 exemptions on this codebase have always come back as separate audit findings. This PR series closes them once.

This is a **pure refactor**: behaviour must be unchanged. Tier-1 standards require zero functional regression — proven by passing existing tests + 240 unchanged golden bytes.

---

## 2. Decisions Required (Socratic gate, pre-answered with specialist input)

| # | Question | Decision | Rationale (specialist) |
|---|----------|----------|------------------------|
| **D1** | One mega-PR for all 9, or split? | **8 PRs total**: 7 per-feature (mapped 1:1 to ownership) + 1 prep PR for issue #203. | architect: 200–400 lines diff each is reviewable in one sitting; mega-PR is 2000+. Per-feature aligns to pizmam's ownership cleanly. |
| **D2** | Sub-widget construction kind | **`StatelessWidget` taking resolved values via constructor params.** `ConsumerWidget` only when child needs notifier method calls AND callback would require 4+ params. | tdd-guide + architect: independent testability without `ProviderScope`; explicit data flow (constructor as documentation); single source of truth for rebuild graph. |
| **D3** | Naming convention for extracted widgets | **Public `PascalCase`** when in own file (all of P-54). **Private `_PascalCase`** only for inline helpers <30 LOC with no test obligation. | architect: addressable + importable + testable; standardises the codebase; worth a §2.2 amendment. |
| **D4** | New shared primitives in `lib/widgets/`? | **Yes — exactly 2:** `SkeletonBone` (used by `detail_loading_view` + future skeletons) and `DiscardChangesDialog` (used by `appeal_screen` + `listing_creation_screen` + future edit flows). | architect: §3.1 "Will 2+ features use it?" rule satisfied for both. Reject `BottomActionBar` (Apple HIG: AppBars are too context-sensitive). |
| **D5** | Payment-critical refactor protocol | **Characterisation tests FIRST**, then extract URL validator to `transaction/domain/`, then refactor view in 2 passes (error view → loading overlay). Never extract `WebViewController` lifecycle. | tdd-guide + architect: Feathers' rule applies — the only place silent regression = money loss. Stripe's checkout-WebView refactor playbook. |
| **D6** | chat_thread + #203 ordering | **Fix #203 in its own PR FIRST**, prove stability across 3 CI runs, THEN decompose `chat_thread_screen.dart`. Decomposition keeps `ScrollController` and `addPostFrameCallback` ownership in the screen. | tdd-guide: avoid the "did decomposition fix #203 by accident?" trap; need the safety net active before refactor. architect: extracting state-bearing scroll behaviour through a widget boundary is precisely what #203 documented. |
| **D7** | Test obligation per extracted widget | **Smoke render mandatory.** Semantics test mandatory if interactive. Interaction test mandatory if it has a callback. Golden only if visually distinctive. | tdd-guide: §6.2 floor not ceiling; Tier-1 (Stripe/Linear) practice is one focused test per public widget. Failure-localisation pays back on second regression. |
| **D8** | Mocking strategy | **`ProviderScope.overrides` + `Fake<EntityRepository>` from `test/mocks/`.** Override the *repository provider*, not the Supabase client. | tdd-guide: matches existing §6.3 pattern; gives compile-time interface coverage + scriptable state transitions. |
| **D9** | Commit granularity per PR | **One commit per file** (9 commits across 7 PRs), risk-ascending within each PR; standard message format. | tdd-guide: makes `git bisect run flutter test` mechanical. Regressions land in <log₂(N)> steps. |
| **D10** | Test file organisation | **One test file per extracted widget**, co-located with source. Strictly enforce — do NOT batch into existing files. | tdd-guide: §2.1's 300-line cap is a forcing function for cohesion; rolling up dilutes the parent test's narrative. |
| **D11** | False-positive decomposition (extract vs inline) | **Extract** when block has >3 testable behaviours OR independent reuse OR >30 LOC. **Inline** below those thresholds. Specifically: `home_data_view` `_trustBanner`/`_categories` are too small to extract — inline them. | architect: premature extraction is the leading indirect cause of "200 files, can't find anything." |
| **D12** | Documentation overhead | Each new widget: `///` doc comment (1-line purpose + screen-spec ref + intentional-deviation notes). **Parent screen does NOT gain a children manifest** — the import block is the manifest, kept fresh by the compiler. | architect: matches Apple SwiftUI + Linear React conventions. Avoid `@author`/`@since` — git blame is the source of truth. |
| **D13** | Coverage gate strategy | Extract + write the sub-widget test in the **same commit**; run `dart run scripts/check_new_code_coverage.dart` locally before push. Parent's `build()` test continues to render the children → indirect coverage preserved. | tdd-guide: changed-lines gate is real but defusable; co-commit is the discipline. |
| **D14** | Goldens regeneration | Goldens must remain **byte-identical** for layout-identical extraction. Any non-zero `git diff --stat test/screenshots/` requires manual visual diff review — do NOT blindly accept `--update-goldens`. | tdd-guide: layout-equivalent regressions in semantic labels (`liveRegion: true` lost) are screen-reader-felt but golden-invisible. |

---

## 3. Per-file decomposition strategy

### Risk-ascending burn-down order

| Order | File | LOC → target | Risk | PR | Rationale |
|------:|------|-------------:|------|-----|-----------|
| 1 | `category_detail_screen.dart` | 228 → ~70 | LOW | PR-C | View-only screen; 3 in-file private classes already factored — promote to siblings |
| 2 | `home_data_view.dart` | 209 → ~90 | LOW | PR-C | View-only; extract 2 sections, inline trivial helpers (D11) |
| 3 | `detail_loading_view.dart` | 225 → ~80 | LOW | PR-D | Skeleton blocks; introduce shared `SkeletonBone` primitive; inline 5 wrappers |
| 4 | `listing_creation_screen.dart` | 204 → ~110 | LOW | PR-G | Step-body switch + leading switch + discard dialog (consumes shared `DiscardChangesDialog` from PR-F) |
| 5 | `search_results_view.dart` | 225 → ~80 | MED | PR-E | Responsive layout coverage critical; split expanded vs compact |
| 6 | `appeal_screen.dart` | 205 → ~120 | MED | PR-F | Draft-save side-effect ordering; extract `AppealAppBar`, introduce shared `DiscardChangesDialog` |
| 7 | `listing_detail_screen.dart` | 205 → ~80 | MED | PR-D | Share/clipboard side effects; promote `_DataView` + split compact/expanded layouts |
| 8 | `chat_thread_screen.dart` | 228 → ~140 | HIGH | PR-B | Golden-test fragility; depends on prep PR-A1 (#203 fix) — extract only the declarative Column body |
| 9 | `mollie_checkout_screen.dart` | 248 → ~140 | **CRITICAL** | PR-A | Payment path; characterisation tests + URL validator extraction first |

### Per-file extraction table

#### File 1 — `mollie_checkout_screen.dart` (248 → ~140 LOC) · PR-A · CRITICAL
| New artefact | Path | Type |
|--------------|------|------|
| `MollieCheckoutLoadingOverlay` | `transaction/presentation/widgets/mollie_checkout_loading_overlay.dart` | StatelessWidget |
| `MollieCheckoutErrorView` | `transaction/presentation/widgets/mollie_checkout_error_view.dart` | StatelessWidget (takes `onRetry`, `onCancel` callbacks) |
| `MollieUrlValidator` (pure) | `transaction/domain/mollie_url_validator.dart` | Pure Dart class (extracted from `_trustedHosts` + URL trust check) |
| `MollieCheckoutBodyFrame` | (already public, untouched) | StatelessWidget |
> **Keep in screen:** `WebViewController` + lifecycle + `setState` flag. Documented at line 14 — respect.

#### File 2 — `chat_thread_screen.dart` (228 → ~140 LOC) · PR-B · HIGH
| New artefact | Path | Type |
|--------------|------|------|
| `ChatThreadBody` | `messages/presentation/widgets/chat_thread_body.dart` | StatelessWidget — header/embed/scam-slot/list/composer Column |
| `ChatScamAlertSlot` | `messages/presentation/widgets/chat_scam_alert_slot.dart` | ConsumerWidget — reads `scamAlertDismissedProvider` (legitimate exception D2) |
> **Keep in screen:** `ScrollController`, `_isNearBottom`, `_scrollToBottom`, `ref.listen` auto-scroll, `_handleSend`/`_handleMakeOffer`/`_handleOfferRespond`.

#### File 3 — `category_detail_screen.dart` (228 → ~70 LOC) · PR-C · LOW
| New artefact | Path | Type |
|--------------|------|------|
| `CategoryDetailDataView` (was `_DataView`) | `home/presentation/widgets/category_detail_data_view.dart` | StatelessWidget |
| `CategorySubcategoryChips` (was `_SubcategoryChips`) | `home/presentation/widgets/category_subcategory_chips.dart` | StatelessWidget |
| `CategoryFeaturedListingCard` (was `_FeaturedListingCard`) | `home/presentation/widgets/category_featured_listing_card.dart` | StatelessWidget |
> **Inline:** `_heroSection` and `_featuredHeader` helpers — too small (D11).

#### File 4 — `detail_loading_view.dart` (225 → ~80 LOC) · PR-D · LOW
| New artefact | Path | Type |
|--------------|------|------|
| `SkeletonBone` (NEW shared) | `lib/widgets/feedback/skeleton_bone.dart` | StatelessWidget — `width`, `height`, `radius` |
> **Inline:** Replace `_bone()` helper + 5 skeleton wrapper classes with `SkeletonBone(...)`. **Net file delete:** none in P-54 scope; consolidation only.

#### File 5 — `search_results_view.dart` (225 → ~80 LOC) · PR-E · MED
| New artefact | Path | Type |
|--------------|------|------|
| `SearchResultsExpanded` | `search/presentation/widgets/search_results_expanded.dart` | StatelessWidget |
| `SearchResultsCompact` | `search/presentation/widgets/search_results_compact.dart` | StatelessWidget |
> **Inline:** `_loadMoreSpinner`, grid trivia.

#### File 6 — `home_data_view.dart` (209 → ~90 LOC) · PR-C · LOW
| New artefact | Path | Type |
|--------------|------|------|
| `HomeNearbySection` | `home/presentation/widgets/home_nearby_section.dart` | StatelessWidget |
| `HomeRecentSection` | `home/presentation/widgets/home_recent_section.dart` | StatelessWidget |
> **Keep:** `_BuyerAppBarActions` (already extracted as private — appropriate per D3). **Inline:** `_trustBanner`, `_categories` (D11).

#### File 7 — `listing_detail_screen.dart` (205 → ~80 LOC) · PR-D · MED
| New artefact | Path | Type |
|--------------|------|------|
| `ListingDetailDataView` (was `_DataView`) | `listing_detail/presentation/widgets/listing_detail_data_view.dart` | StatelessWidget |
| `ListingDetailCompactLayout` | `listing_detail/presentation/widgets/listing_detail_compact_layout.dart` | StatelessWidget |
| `ListingDetailExpandedLayout` | `listing_detail/presentation/widgets/listing_detail_expanded_layout.dart` | StatelessWidget |
| `ListingDetailActions` (controller, side-effects) | `listing_detail/presentation/listing_detail_actions.dart` | Plain Dart class |
> **Shared `_detailSlivers` builder** stays in `ListingDetailDataView`.

#### File 8 — `appeal_screen.dart` (205 → ~120 LOC) · PR-F · MED
| New artefact | Path | Type |
|--------------|------|------|
| `AppealAppBar` | `profile/presentation/widgets/appeal_app_bar.dart` | StatelessWidget |
| `AppealDiscardDialog` (was inline) | replaced by `DiscardChangesDialog` (NEW shared) | StatelessWidget |
| `DiscardChangesDialog` (NEW shared) | `lib/widgets/dialogs/discard_changes_dialog.dart` | StatelessWidget — `title`, `message`, `confirmLabel` params |
| `appealBodyProvider` (was `_AppealBody`) | `profile/presentation/viewmodels/appeal_body_provider.dart` | Riverpod provider |
> **Keep in screen:** State, `PopScope`, `_canPop` wiring.

#### File 9 — `listing_creation_screen.dart` (204 → ~110 LOC) · PR-G · LOW (depends on PR-F)
| New artefact | Path | Type |
|--------------|------|------|
| `ListingCreationStepBody` (was `_buildStepView` switch) | `sell/presentation/widgets/listing_creation_step_body.dart` | StatelessWidget |
| `ListingCreationLeading` (was `_buildLeading` switch) | `sell/presentation/widgets/listing_creation_leading.dart` | StatelessWidget |
| `ListingDiscardDialog` consumes `DiscardChangesDialog` | (no new file) | — |
> **Keep:** `ref.listen` orchestration + `PopScope`.

---

## 4. Shared primitives (decision D4)

### `SkeletonBone` (NEW)
- **Path:** `lib/widgets/feedback/skeleton_bone.dart`
- **API:** `SkeletonBone({required double width, required double height, double radius = 4})`
- **Reason:** detail_loading_view's bespoke `_bone()` helper is a §3.3 (DRY) violation; future skeleton work for other features needs the same primitive.
- **Test:** `test/widgets/feedback/skeleton_bone_test.dart` — render + golden (light/dark).

### `DiscardChangesDialog` (NEW)
- **Path:** `lib/widgets/dialogs/discard_changes_dialog.dart`
- **API:** `DiscardChangesDialog.show(context, {required String title, required String message, required String confirmLabel, String? cancelLabel}) → Future<bool>`
- **Reason:** identical pattern in `appeal_screen` and `listing_creation_screen`; `lib/features/sell/edit/` will need it next sprint.
- **Test:** `test/widgets/dialogs/discard_changes_dialog_test.dart` — render + tap-confirm + tap-cancel + dismissed (returns false).

---

## 5. Refactor protocol per risk tier

### CRITICAL (mollie_checkout) — 5-step protocol
1. **Audit existing tests** under `test/features/transaction/`. If coverage of trusted-host validator + redirect detector + retry path + cancel path < 100%, write characterisation tests against current shape.
2. **Extract pure logic upward** — move `_trustedHosts` + URL trust check to `transaction/domain/mollie_url_validator.dart`. Pure Dart → 100% unit-testable, no widget tree. **Clean Architecture win independent of LOC.**
3. **Refactor pass A:** extract error view (`MollieCheckoutErrorView`) — pure relocation, `_retry` callback wired through `VoidCallback`. Run characterisation suite.
4. **Refactor pass B:** extract loading overlay (`MollieCheckoutLoadingOverlay`). Run characterisation suite + goldens + screenshot drivers.
5. **Manual verification on staging:** complete one full Mollie iDEAL test transaction (sandbox). Confirm Sentry breadcrumb chain unchanged.

### HIGH (chat_thread) — 4-step protocol
1. **Pre-PR:** `PR-A1` lands a fix for #203 (separate scope). Un-skip `chat_thread_screenshot_test.dart`. Prove stable across 3 CI runs.
2. Extract only the **declarative Column body** as `ChatThreadBody` (`StatelessWidget` taking `state`, `colors`, `scrollController`, 3 callbacks).
3. Extract `ChatScamAlertSlot` as `ConsumerWidget` (legitimate D2 exception — needs `scamAlertDismissedProvider`).
4. Regenerate goldens **with manual visual diff review** on dark-mode + LTR + 360-px variant minimum.

### MED (4 files: search, appeal, listing_detail, listing_creation)
1. Identify extraction seams per §3 table.
2. Extract one widget per commit, co-commit its test.
3. Run `flutter test test/features/<feature>/` after each commit.
4. Run `flutter test --update-goldens` on a throwaway branch first; review byte-diff before accepting.

### LOW (3 files: category_detail, home_data_view, detail_loading_view)
1. Extract per §3 table; co-commit tests.
2. Run feature test + golden suite. Land.

---

## 6. PR sequencing (8 PRs total)

| PR | Title | Files affected | Depends on | Effort |
|----|-------|----------------|-----------|--------|
| **A1** | `fix(messages): resolve chat_thread golden pre-paint capture (#203)` | `chat_thread_screenshot_test.dart` (un-skip) + minimal source change | — | S (½ day) |
| **C** | `refactor(home): decompose category_detail + home_data_view (P-54)` | files 3 + 6 | — | S (1 day) |
| **D** | `refactor(listing_detail): decompose detail screen + introduce SkeletonBone (P-54)` | files 4 + 7 + new shared `SkeletonBone` | — | M (1.5 days) |
| **E** | `refactor(search): decompose search_results_view (P-54)` | file 5 | — | S (1 day) |
| **F** | `refactor(profile): decompose appeal_screen + introduce DiscardChangesDialog (P-54)` | file 8 + new shared `DiscardChangesDialog` | — | M (1.5 days) |
| **G** | `refactor(sell): decompose listing_creation (P-54)` | file 9 | **PR-F** (uses `DiscardChangesDialog`) | M (1 day) |
| **B** | `refactor(messages): decompose chat_thread_screen (P-54)` | file 2 | **PR-A1** | M (1 day) |
| **A** | `refactor(transaction): decompose mollie_checkout — payment-critical (P-54)` | file 1 + extracted domain | — (independent) | M (2 days) |

> **Total calendar:** 1.5–2 weeks if sequential. PR-C, PR-D, PR-E, PR-F, PR-A can be authored in parallel by pizmam (no dependency); PR-G follows PR-F; PR-B follows PR-A1.

> **Branch naming convention** (CLAUDE.md §5.2): `feature/pizmam-audit-P54-<scope>` — e.g. `feature/pizmam-audit-P54-home`, `feature/pizmam-audit-P54-mollie`.

---

## 7. Mandatory rule consultation

| Rule | Applicable? | How addressed |
|------|-------------|---------------|
| §1.2 Layer dependency | **Yes** — extracted widgets stay in `presentation/widgets/`; pure logic moves to `domain/` (mollie URL validator only) | All extractions per §1.2 directionality |
| §2.1 File length | **PRIMARY MOTIVATION** — every artefact ≤ §2.1 budget per type | Each extracted widget ≤ 200 LOC; tests ≤ 300 LOC |
| §2.2 Naming | **Yes** | D3 standardises Public PascalCase for own-file widgets, `_PascalCase` for inline |
| §3.1 Shared widgets | **Yes** | D4 introduces `SkeletonBone` + `DiscardChangesDialog` to `lib/widgets/` (≥2 future call sites confirmed) |
| §3.3 No duplication | **Yes** | `_bone()` helper de-duplicated via `SkeletonBone`; identical discard dialogs de-duplicated |
| §4 Design system | **Yes** | All extractions preserve token usage (DeelmarktColors / Spacing / DeelmarktTypography); no new raw values |
| §6.1 Coverage | **Yes** | 80% on changed lines (CI floor); **100% on `mollie_checkout_screen.dart` and any extracted children** (payment path) |
| §6.2 Test layer matrix | **Yes** | New shared widgets get widget tests (mandatory); feature widgets follow D7 test obligations |
| §6.3 Mocking | **Yes** | D8 uses `ProviderScope.overrides` + `Fake` repos from `test/mocks/` |
| §7.5 UI tasks | **Yes** | Each extracted screen gets `/// Reference: docs/screens/...` doc comment per §7.1 |
| §8 Quality Gates | **Yes** | Pre-commit + pre-push hooks unchanged; check_quality.dart strict |
| §10 Accessibility | **Yes — critical** | Every extracted interactive widget preserves Semantics labels; tests assert Semantics presence (D7) |
| §13 Marketing assets | No | — |

### `/quality-gate` Ethics & Safety Pass

| Domain | Result |
|--------|--------|
| **AI Bias** | N/A — pure refactor, no algorithmic surface |
| **GDPR / Privacy** | N/A — no data flow change. Verify Sentry breadcrumb chain in mollie unchanged (data lineage preserved). |
| **Automation Safety** | ⚠️ Risk: silent semantic loss (e.g. `liveRegion: true` dropped during extraction). Mitigation: D7 mandates Semantics tests on interactive extracts. |
| **User Autonomy** | N/A |
| **Human-in-the-Loop** | ✅ All decompositions reviewed by human; mollie + chat_thread require explicit reviewer sign-off (mahmutkaya). |

**Ethics verdict: ✅ APPROVED.** No rejection trigger fires.

### Competitive market reference (per `/quality-gate` Step 1)

| Tier-1 reference | Practice | Applied here |
|------------------|----------|--------------|
| Stripe (checkout WebView) | Characterisation tests first; pure-logic up to domain | mollie protocol §5 |
| Linear (React component conventions) | One file per public widget; Public PascalCase | D3 + §3 table |
| Apple SwiftUI | Parent has no children manifest; import block IS the manifest | D12 |
| Vinted (Flutter marketplace) | StatelessWidget extraction with prop-passing default | D2 |
| Material 3 / Apple HIG | Reject `BottomActionBar` shared primitive — context-sensitive | §4 (negative decision) |

**Differentiation:** the §6.1 100%-payment-coverage rule + Semantics-test-on-interactive-extract rule together exceed Vinted's published widget-test discipline. This refactor preserves that bar.

---

## 8. Implementation tasks (per PR)

### PR-A1 — Fix #203 chat_thread golden (½ day)
- [ ] Investigate the pre-paint capture issue (likely missing `pumpAndSettle` after first frame OR `addPostFrameCallback` racing the test harness)
- [ ] Apply minimal source/test change to stabilise
- [ ] Un-skip `chat_thread_screenshot_test.dart` (`skip: true` → removed)
- [ ] Verify 3 consecutive green CI runs
- [ ] Land

### PR-C — Home decomposition (1 day)
- [ ] Extract `CategoryDetailDataView`, `CategorySubcategoryChips`, `CategoryFeaturedListingCard` from `category_detail_screen.dart`
- [ ] Extract `HomeNearbySection`, `HomeRecentSection` from `home_data_view.dart`
- [ ] Inline `_trustBanner`, `_categories` per D11
- [ ] Co-commit 5 widget tests
- [ ] Verify both files ≤ 200 LOC; goldens unchanged

### PR-D — Listing-detail + SkeletonBone (1.5 days)
- [ ] Create `lib/widgets/feedback/skeleton_bone.dart` + test (render + golden light/dark)
- [ ] Replace `_bone()` + 5 skeleton classes in `detail_loading_view.dart` with `SkeletonBone`
- [ ] Extract `ListingDetailDataView`, `ListingDetailCompactLayout`, `ListingDetailExpandedLayout`
- [ ] Extract `ListingDetailActions` (controller class for share/clipboard side-effects)
- [ ] Co-commit 5 widget tests + 1 controller test
- [ ] Verify both files ≤ 200 LOC

### PR-E — Search decomposition (1 day)
- [ ] Extract `SearchResultsExpanded`, `SearchResultsCompact`
- [ ] Inline `_loadMoreSpinner` + grid trivia
- [ ] Co-commit 2 widget tests covering responsive variant matrix (compact + expanded)
- [ ] Verify file ≤ 200 LOC

### PR-F — Appeal + DiscardChangesDialog (1.5 days)
- [ ] Create `lib/widgets/dialogs/discard_changes_dialog.dart` + test (4 cases)
- [ ] Migrate `appeal_screen.dart` to consume `DiscardChangesDialog`
- [ ] Extract `AppealAppBar`
- [ ] Move `_AppealBody` provider to `viewmodels/appeal_body_provider.dart`
- [ ] Co-commit widget tests
- [ ] Verify file ≤ 200 LOC

### PR-G — Listing-creation (1 day) — **depends on PR-F merging**
- [ ] Rebase on `dev` after PR-F
- [ ] Extract `ListingCreationStepBody`, `ListingCreationLeading`
- [ ] Migrate inline discard dialog to `DiscardChangesDialog`
- [ ] Co-commit widget tests
- [ ] Verify file ≤ 200 LOC

### PR-B — Chat-thread decomposition (1 day) — **depends on PR-A1 merging**
- [ ] Rebase on `dev` after PR-A1
- [ ] Extract `ChatThreadBody` (StatelessWidget) — keep ScrollController + auto-scroll in screen
- [ ] Extract `ChatScamAlertSlot` (ConsumerWidget — legitimate D2 exception)
- [ ] Co-commit 2 widget tests
- [ ] Run `flutter test --update-goldens` on throwaway branch; manual visual diff on dark + LTR + 360px
- [ ] Verify file ≤ 200 LOC + goldens stable

### PR-A — Mollie checkout decomposition (2 days)
- [ ] **Step 1:** audit existing payment-test coverage; write characterisation tests if < 100%
- [ ] **Step 2:** extract `MollieUrlValidator` to `transaction/domain/`; 100% unit test
- [ ] **Step 3 (pass A):** extract `MollieCheckoutErrorView`; run characterisation suite
- [ ] **Step 4 (pass B):** extract `MollieCheckoutLoadingOverlay`; run characterisation suite + goldens
- [ ] **Step 5:** manual sandbox iDEAL transaction on staging; verify Sentry breadcrumb chain
- [ ] Co-reviewer: belengaz (payment scope) + mahmutkaya (architecture)
- [ ] Verify file ≤ 200 LOC

---

## 9. Cross-cutting concerns

### Security / Privacy
- ✅ No data-flow change in any extraction
- ✅ Mollie URL validator extraction strengthens trust-host check (becomes pure-logic, fully testable)
- ✅ Sentry breadcrumb chain explicitly verified in PR-A step 5
- ✅ No new attack surface

### Testing
- 80% on changed lines (CI floor) — pre-push gate `check_new_code_coverage.dart`
- 100% on `mollie_checkout_screen.dart` + extracted children (CLAUDE.md §6.1)
- D7 test obligations per extracted widget (smoke / semantics / interaction / golden)
- Feathers-style characterisation tests on payment path (D5)
- D9 commit granularity for bisect-safety

### Documentation
- Each extracted widget: `///` doc with screen-spec ref + intentional-deviation notes
- ADR not required (no architectural seam — refactor preserves existing seam)
- CHANGELOG entry per PR
- `docs/SCREENS-INVENTORY.md`'s "§2.1 budget breach" warnings (added in P-57) → cleared as files drop below 200 LOC

### Accessibility
- **Critical concern.** Every extraction must preserve Semantics labels, `liveRegion`, `excludeSemantics`, focus order
- D7 mandates Semantics test for every interactive extract — the regression net for this concern
- WCAG 2.2 AA + EAA compliance unchanged

### Localisation
- All `.tr()` keys preserved verbatim; no l10n changes
- en-US.json + nl-NL.json untouched

### Performance
- Extraction is rebuild-graph-neutral when StatelessWidget (D2)
- chat_thread protocol §5 specifically defends against `addPostFrameCallback` ordering changes
- Watch for `RepaintBoundary` / `Builder` introductions per tdd-guide Q3

### Observability
- No new traces (P-56 already shipped); existing instrumentation preserved
- Sentry breadcrumb chain explicitly verified in PR-A

---

## 10. Risk matrix

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|-----------|--------|-----------|
| **R1** | Mollie payment regression | Low | **CRITICAL (money loss)** | Characterisation tests first; sandbox iDEAL test; co-review by belengaz |
| **R2** | chat_thread golden destabilisation | Medium | High | PR-A1 fixes #203 first; manual visual diff on dark/LTR/360px |
| **R3** | Semantics label silently dropped | Medium | High (a11y regression) | D7 mandatory Semantics test on interactive extracts |
| **R4** | Coverage gate false-fail (80% on changed lines) | Medium | Medium | D13 co-commit discipline; local check before push |
| **R5** | Goldens diverge on layout-equivalent extraction | Low | Medium | tdd-guide Q3 anti-patterns avoided (no new Builder/LayoutBuilder/RepaintBoundary) |
| **R6** | PR-G blocked on PR-F merge delay | Medium | Low | Rebase frequently; PR-F has reviewer SLA escalation if >2d |
| **R7** | PR-B blocked on PR-A1 #203 fix | Low | Medium | PR-A1 is small + isolated; expect <½ day |
| **R8** | Conflict surface with concurrent sprint work | Medium | Medium | Per-feature PR scope minimises rebase pain (D1) |
| **R9** | False-positive extraction (over-engineering) | Low | Low | D11 thresholds; reviewer enforcement |
| **R10** | Test file >300 LOC (D10 violation) | Low | Low | D10 strict — one test file per widget |
| **R11** | Extracted widget API drift (params reordered) | Low | Low | Constructor params named (Dart convention); no positional args >2 |
| **R12** | Premature `lib/widgets/` promotion | Low | Low | D4 limited to 2 primitives with verified ≥2 call-site reuse |

---

## 11. Multi-level rollback

| Level | Action | Effect |
|-------|--------|--------|
| **L1 — Per-commit revert** | `git revert <commit-sha>` of single extraction | Single screen returns to pre-P54 shape; tests + goldens reset |
| **L2 — Per-PR revert** | `git revert -m 1 <merge-sha>` of one PR | One feature folder restored; other 6 PRs unaffected |
| **L3 — PR-A emergency** (mollie regression) | Hot-fix release reverting only PR-A; other PRs stay | Payment path restored; rest of audit gain preserved |
| **L4 — Shared primitive revert** | Revert `SkeletonBone` or `DiscardChangesDialog` introduction | Consumers (PR-D, PR-F, PR-G) need their own follow-up reverts |
| **L5 — Full series revert** | Sequence of L2 reverts in reverse merge order | Dev tree returns to pre-P54 state; ~25 file deletions |

> **Rollback eligibility:** L1–L3 are unconditional; L4 requires consumer cleanup; L5 is last-resort full rollback.

---

## 12. Quality gate checklist (per PR)

| Gate | Owner | Evidence |
|------|-------|---------|
| `flutter analyze --fatal-infos` zero issues | pizmam | CI |
| `flutter test` zero failures | pizmam | CI |
| Coverage ≥ 80% on changed lines | pizmam | `check_new_code_coverage.dart` pre-push |
| Coverage 100% on payment path (PR-A only) | pizmam + belengaz | CLAUDE.md §6.1 enforced |
| `dart run scripts/check_quality.dart --all` zero violations | pizmam | CI |
| Goldens byte-identical OR manually reviewed visual diff | pizmam | `git diff --stat test/screenshots/` |
| Each extracted widget has matching test file | pizmam | `find lib/.../widgets/ -name '*.dart' \| xargs -I{} test -f test/{}_test.dart` |
| Each interactive extracted widget has Semantics assertion | pizmam | grep test files |
| Touch targets ≥44×44px preserved (§10) | pizmam | Visual review |
| `dart format` + pre-commit hooks pass | pizmam | Auto |
| Reviewer approval | belengaz (PR-A, PR-B) + reso (architecture spot-check) | GitHub PR |

---

## 13. Definition of Done (numerical bar)

P-54 is complete if and only if **all 11 thresholds** below hold:

1. ✅ `flutter analyze --fatal-infos` — zero warnings
2. ✅ All 9 target files ≤ **200 LOC** (CLAUDE.md §2.1)
3. ✅ All extracted sub-widget files ≤ **200 LOC** each
4. ✅ All new test files ≤ **300 LOC** each
5. ✅ `flutter test` — 100% pass, **zero new `skip:true`**
6. ✅ `check_new_code_coverage.dart` — **≥80%** on changed lines; **100%** on `mollie_checkout_screen.dart` and extracted children
7. ✅ Golden suite: **240/240 unchanged bytes** verified via `git diff --stat test/screenshots/`
8. ✅ `chat_thread_screenshot_test.dart` either still skipped *with the same `#203` annotation* OR un-skipped and passing (no silent re-skip)
9. ✅ Each commit individually green under `flutter test` (bisect-safe — D9)
10. ✅ `check_quality.dart --all` — zero violations introduced
11. ✅ Nine commits, one per file (across 7 PRs), risk-ascending order, standard message format

If any of these eleven fails, P-54 is not done — regardless of how green the final CI looks.

---

## 14. Provenance

- **Workflow:** `.agent/workflows/plan.md` v2.2.0 (Large track) + `/quality-gate` v2.1.0 (full Ethics & Safety pass — ✅ APPROVED) + Specialist Synthesis Protocol
- **Specialist input received:**
  - **Architect (Opus 4.7)** — per-file extraction strategy table, common patterns + 2 shared primitives, payment refactor protocol, chat_thread golden risk, PR structure (7 PRs), test seam boundary, Riverpod boundary, naming convention (D3), false-positive avoidance (D11), documentation overhead (D12)
  - **TDD-guide (Opus 4.7)** — characterisation-test mandate for payment path, coverage delta defusal (D13), golden-test detection protocol (D14), #203 sequencing (D6), per-widget test obligation (D7), Riverpod test seam, mocking strategy (D8), bisect commit granularity (D9), test file organisation (D10), CI cost analysis, anti-pattern catalogue, 11-point Definition of Done
- **Audit cross-references:** `docs/audits/2026-04-25-tier1-retrospective.md#p-54`, `docs/audits/2026-04-25-tier1-preflight.md` finding `M1`
- **Rule bases:** CLAUDE.md §1.2 / §2.1 / §2.2 / §3.1 / §3.3 / §4 / §6.1 / §6.2 / §6.3 / §7.5 / §8 / §10
- **Differentiation evidence:** competitor matrix (Stripe / Linear / Apple SwiftUI / Vinted / Material 3) — DeelMarkt's combined 100%-payment-coverage + Semantics-test-on-interactive-extract bar exceeds Vinted's published practice
- **Companion plan:** P-55 (admin-widget decomposition) follows the same protocol on a smaller scope; can land before or after P-54 burn-down completes
