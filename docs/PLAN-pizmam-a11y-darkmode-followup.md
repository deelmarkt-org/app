# PLAN — Pizmam Accessibility (P-42) + Dark Mode (P-47) Follow-Up

> **Status:** ✅ **COMPLETED** — shipped via [PR #168](https://github.com/deelmarkt-org/app/pull/168) (merged 2026-04-23). Issue [#156](https://github.com/deelmarkt-org/app/issues/156) closed.
> _Doc preserved for historical reference. Acceptance items below were satisfied at merge time; PR review + CI is the source of truth._
>
> **Owner:** pizmam (`[P]`)
> **Issues:** [#156](https://github.com/deelmarkt-org/app/issues/156) (P-42 EAA blockers + 6 quality gaps) · [#158](https://github.com/deelmarkt-org/app/issues/158) (P-47 dark-mode follow-up + sprint-plan correction)
> **Source PRs (already merged):** [#155](https://github.com/deelmarkt-org/app/pull/155) (P-42) · [#157](https://github.com/deelmarkt-org/app/pull/157) (P-47)
> **Branch:** `feature/pizmam-a11y-darkmode-followup` (off `origin/dev`)
> **Estimate:** ~2 developer-days (1 day code + 0.5 day tests + 0.5 day visual QA / regression)
> **Tier:** Medium (5–7 source files + tests + docs + l10n)
> **Produced via:** `.agent/workflows/plan.md` (Tier-1 schema, Specialist Synthesis Protocol)

---

## 1 · Context & Problem Statement

PR #155 ("P-42 — WCAG 2.2 AA accessibility audit") and PR #157 ("P-47 — dark mode")
were both merged in mid-April 2026. Post-merge Tier-1 retrospectives identified:

- **2 P0 blockers** under the European Accessibility Act (EAA, enforceable since
  June 28 2025; fines up to €100 000 or 4 % of revenue) — touch-target & screen-reader
  gaps in consent and trust UI.
- **6 quality regressions / gaps** of varying priority that prevent the sprint plan
  P-42 line from being legitimately marked complete.
- **3 hardcoded `DeelmarktColors.white` references** in non-admin widgets that PR #157
  intentionally left out-of-scope (admin-only PR) but produce visible defects in
  dark mode.
- **A sprint-plan inconsistency**: PR #157 commit 3 prematurely marked P-42 complete
  while #156 still has open EAA blockers.

This plan resolves all of the above in a single, cohesive PR so the sprint plan is
truthful, the launch is unblocked from a legal-compliance standpoint, and the dark
mode rollout is internally consistent.

## 2 · Goals & Non-Goals

### Goals

1. **Close all P0/P1 EAA blockers** in #156 so the app meets WCAG 2.2 AA on the
   consent flow, parcel-shop selector, and scam-alert UI.
2. **Resolve the 3 dark-mode hardcoded-white regressions** in `chat_message_composer`,
   `sold_overlay`, and `splash_screen`.
3. **Add `error.url_open_failed` localised string** so the new SnackBar in M2 is
   bilingual (NL + EN) per `core/l10n` rules.
4. **Add unit + widget test coverage** that mathematically locks the new behaviours
   (≥ 80 % on changed files, mirroring SonarCloud gate).
5. **Correct `docs/SPRINT-PLAN.md`** to reflect the truthful state of P-42 (still
   blocked by #156 → revert to `[ ]`, then this PR satisfies it and re-marks `[x]`).
6. **Document the L1 spec/legal decision** on combined-vs-separate consent
   checkboxes (decision recorded; spec or implementation aligned).

### Non-Goals

- L3 systematic P-42 audit across all 31 screens (separate Tier-1 audit task —
  out of scope for this fix-up PR; would balloon scope > 500 LOC).
- Issue [#162](https://github.com/deelmarkt-org/app/issues/162) (ASO
  `privacy_details.yaml`) — owned by belengaz, DevOps domain.
- Issue [#164](https://github.com/deelmarkt-org/app/issues/164) (dark-mode chat
  thread golden PNG) — blocked on designer handoff, will ship as separate
  one-line PR once asset arrives.
- Re-architecting `ConsentCheckboxes` to use `RichText`/`TextSpan` recogniser
  patterns (PR #155 already replaced these with `Semantics(link:true)` + `InkWell`;
  reverting would be a regression).
- New screens or new features. **This is a fix-up PR exclusively.**
- Touching `parcel_shop_list_item.dart` for H2 — verification confirmed it
  already has `Semantics(label:..., button:true)` on `origin/dev` (someone fixed
  it post-#156 filing). Plan still includes a one-line verification step.

## 3 · Current-State Audit (verified against `origin/dev`)

| File | Issue Item | State on `origin/dev` | Action Needed |
|:-----|:-----------|:----------------------|:--------------|
| `lib/features/auth/presentation/widgets/consent_checkboxes.dart` | H1, M1, M2, M4 | `_ConsentRow` exists, `InkWell` wraps bare `Text` (no padding), `launchUrl` discards `Future<bool>`, no `LaunchMode`, `theme` injected via constructor, `ConsentCheckboxes` is `StatefulWidget` with no state. | **Fix all 4** (H1, M1, M2, M4). |
| `lib/features/shipping/presentation/widgets/parcel_shop_list_item.dart` | H2 (part 1) | ✅ Already has `Semantics(label: '...', button: true, selected: ...)` — fixed by a parallel commit after #156 was filed. | **Verify only** — add a regression test, no source change. |
| `lib/widgets/trust/scam_alert_actions.dart` | H2 (part 2) | ❌ Both `_ReportButton` and `_InlineDismissButton` use `Semantics(button: true)` with no `label:`. Screen reader announces "button" with no purpose. | **Add `label:` to both** (P0). |
| `test/features/auth/presentation/widgets/consent_checkboxes_test.dart` | M3 | Has 7 tests but no semantic-label association test, no `launchUrl` mock test, no touch-target assertion. | **Add 4 tests** (M3, L2, H1 regression). |
| `lib/features/messages/presentation/widgets/chat_message_composer.dart` | #158 file 1 | Send button uses `DeelmarktColors.white` for icon + spinner color (lines 184, 190). | **Replace with `Theme.of(context).colorScheme.onPrimary`.** |
| `lib/features/listing_detail/presentation/widgets/sold_overlay.dart` | #158 file 2 | `neutral900.withValues(alpha: 0.7)` background is **always dark** regardless of theme; `white` text on top is **correct**. Issue asks for visual QA. | **Add `// Intentional: overlay is theme-independent` comment** + dark-mode golden test. No color change. |
| `lib/core/router/splash_screen.dart` | #158 file 3 | Uses explicit `isDark ? darkScaffold : white` ternary. Works correctly. Issue says "consider migrating to `colorScheme.surface`". | **Defer with rationale** (cross-domain — `lib/core/router/` is belengaz scope; ternary is not a defect, only a style suggestion). Open follow-up issue if approved. |
| `assets/l10n/en-US.json` + `nl-NL.json` | M2 dependency | No `error.url_open_failed` key exists. | **Add NL + EN strings.** |
| `docs/SPRINT-PLAN.md` | #158 last AC | P-42 is currently `[ ]` and references "PR #155 open (EAA blockers: issue #156)". Truth is PR #155 merged but #156 still open. | **Correct to** `[ ] ... — blocked by #156` **then this PR satisfies #156 and the next commit on this branch flips to `[x]`.** |

**Key insight:** The audit downgrades the original combined #156+#158 scope.
**Two of the originally listed file changes are not needed** (parcel_shop already
fixed; sold_overlay is intentional). One file change is **deferred for cross-domain
respect** (splash_screen is in belengaz's `lib/core/router/`). The PR shrinks to
**4 source files + 1 test file + 2 l10n files + 1 doc**, well under the 500-LOC
PR-size limit.

## 4 · Specialist Synthesis (per `planningMandates.specialistContributors`)

### 4.1 `security-reviewer` — Threat Assessment

| Threat | Severity | Mitigation | Verified By |
|:-------|:---------|:-----------|:------------|
| **WebView phishing via in-app browser** — without `LaunchMode.externalApplication`, Terms/Privacy may open in an in-app WebView where users can't verify the URL or TLS certificate. Attackers could inject a fake T&C page. | High | M2: Force `LaunchMode.externalApplication` in `launchUrl`. | Widget test verifying mode parameter on URL launcher mock. |
| **Silent consent bypass** — `launchUrl` returning `false` is dropped; if Terms link fails to open, the user may still tick the checkbox without ever reading the document → invalid GDPR Art. 7 consent. | High | M2: Capture return value, surface SnackBar with `error.url_open_failed`, do not auto-tick. | Widget test forcing `UrlLauncherPlatform` to return `false`, asserting SnackBar appears. |
| **Touch hijacking on small targets** — sub-44dp targets are easier to mis-tap, especially adjacent to other interactive elements; in trust UI (scam-alert) a mis-tap could dismiss a real warning. | High (legal) | H1: Wrap `InkWell` `Text` in `EdgeInsets.symmetric(vertical: 12)` to expand to ≥44dp. H2: Already-44dp scam-alert buttons get `label:` so screen-reader users have parity. | Widget test: `tester.getSize(find.byType(InkWell)).height >= 44`. |
| **Screen-reader silent failure** — scam-alert buttons announce as "button" with no purpose; visually impaired users cannot distinguish "report" from "dismiss" → trust safety failure. | Critical | H2: Add `label: 'scam_alert.report'.tr()` and `label: 'scam_alert.dismiss'.tr()`. | Widget test: `tester.getSemantics(find.byType(_ReportButton)).label` contains the localised string. |
| **Locale gap** — adding `error.url_open_failed` only in EN would crash the NL build at runtime when easy_localization throws `LocalizationKeyNotFoundException`. | Medium | Both `en-US.json` and `nl-NL.json` updated atomically in the same commit. | `dart run scripts/check_quality.dart` (l10n parity check). |

### 4.2 `tdd-guide` — Test Strategy

**Test Pyramid:** 100 % unit (l10n key existence) · 90 % widget (a11y + dark mode) · 0 % e2e (covered by existing screenshot suite once goldens regen).

| Layer | New Tests | Existing Tests Touched | Coverage Target |
|:------|:----------|:------------------------|:----------------|
| `consent_checkboxes_test.dart` | M3: semantic-label association test (verifies `Semantics` link node composes with checkbox name) · H1 regression: `tester.getSize` on `InkWell` ≥ 44 dp · L2a: `UrlLauncherPlatform` mock — terms link calls `AppConstants.termsUrl` · L2b: `UrlLauncherPlatform` mock — privacy link calls `AppConstants.privacyUrl` · L2c: `UrlLauncherPlatform` mock — `false` return surfaces SnackBar with `error.url_open_failed` | Existing 7 tests untouched (regression-safe) | 100 % on the changed widget |
| `scam_alert_actions_test.dart` (extend or create) | H2: `tester.getSemantics(...).label` contains `scam_alert.report` / `scam_alert.dismiss` | None | 100 % on changed file |
| `parcel_shop_list_item_test.dart` (regression test) | H2 verify-only: assert label includes `shop.name` and "button" semantic flag — locks the existing fix in place | None | Already 100 %; this just adds a guard |
| `chat_message_composer_test.dart` | Dark-mode golden: send button icon uses `colorScheme.onPrimary` (not raw `white`) | None (golden may need regen) | Existing tests untouched |
| `sold_overlay_test.dart` | Dark-mode golden — captures the always-dark overlay correctness | None | Net new |
| `assets/l10n/*.json` parity | Existing `strings_test.dart` automatically validates new keys exist in both files | Auto-covered | n/a |

**Mock strategy:** `UrlLauncherPlatform` mock via `MockPlatformInterfaceMixin` —
already used elsewhere in the codebase, no new dependency.

### 4.3 `architect` — Architecture Impact

This is a **defect-fix PR**, not an architecture change. Layer boundaries (Clean
Architecture / MVVM / Riverpod) are unchanged. Specifically:

- **No new entities, repositories, or use cases.**
- **No new Riverpod providers.**
- **No new database tables, RLS policies, or Edge Functions.**
- **No new public API surface** on widgets (the only constructor change is *removing*
  the `theme` parameter from `_ConsentRow` — a private widget, no consumers outside
  `consent_checkboxes.dart`).
- **One private-to-private widget conversion** (`StatefulWidget` → `StatelessWidget`
  for `ConsentCheckboxes`). The public constructor signature is preserved exactly
  so all callers (registration screen, tests) compile without modification.

The only architectural concern is **cross-domain ownership**: `splash_screen.dart`
and `parcel_shop_list_item.dart` live under domains owned by belengaz. Decision:
- `parcel_shop_list_item.dart` — verify-only (no source change), so domain crossing
  is **non-existent** (we only add a *test* in `test/features/shipping/` which is
  pizmam's testing scope under §6.2).
- `splash_screen.dart` — **defer**. Open a follow-up issue addressed to belengaz
  (or the cross-domain triage process) so we don't unilaterally edit `lib/core/router/`.

## 5 · Pre-Implementation Verification (CLAUDE.md §7.1)

### 5.1 Schema (DB tables / columns I will query)

**N/A** — this PR touches no database, no Supabase queries, no Edge Functions.

### 5.2 Sibling conventions

- `lib/widgets/trust/scam_alert_actions.dart` — sibling `scam_alert.dart` already
  uses `Semantics(button: true, label: ...)` on the inline dismiss icon (verified
  via grep). Convention match: ✅.
- `lib/features/auth/presentation/widgets/consent_checkboxes.dart` — sibling
  `consent_banner.dart` (top-level) uses `Theme.of(context)` internally (no
  parameter injection). Convention match for M1 fix: ✅.
- `assets/l10n/*.json` — `error.*` namespace already contains `generic`, `network`,
  `payment_failed`, `image_upload_failed`, etc. Convention: snake_case, plain
  string. New key `error.url_open_failed` matches: ✅.

### 5.3 Epic acceptance-criteria audit

| Source | Criterion | Coverage |
|:-------|:----------|:---------|
| #156 H1 | InkWell ≥ 44 dp vertical touch target | ✅ Fully |
| #156 H2 (parcel_shop) | `Semantics(label:)` present | ✅ Already done — regression-test only |
| #156 H2 (scam_alert × 2) | `Semantics(label:)` present | ✅ Fully |
| #156 M2 | `LaunchMode.externalApplication` + `false` SnackBar | ✅ Fully |
| #156 M3 | Semantic-label association test | ✅ Fully |
| #156 M1 | `_ConsentRow` reads theme via `Theme.of(context)` | ✅ Fully |
| #156 M4 | `ConsentCheckboxes` → `StatelessWidget` | ✅ Fully |
| #156 L1 | Spec vs implementation alignment | 🟡 Partial — decision documented in plan §7.1; if "two checkboxes" wins, update `docs/screens/01-auth/02-registration.md` line 7. If "one combined" wins, restructure (out of scope for this PR — would require new `auth.terms_checkbox` parameterised string). **Default: keep two checkboxes (better GDPR Art. 7 granularity), update spec.** |
| #156 L2 | URL-launcher mock tests | ✅ Fully (folded into M3) |
| #156 L3 | Full systematic audit | ❌ Out of scope (separate Tier-1 task) |
| #158 file 1 | `chat_message_composer` dark-mode color | ✅ Fully |
| #158 file 2 | `sold_overlay` dark-mode QA | ✅ Verify + comment + golden |
| #158 file 3 | `splash_screen` dark-mode polish | 🟡 Deferred — cross-domain (belengaz). Follow-up issue. |
| #158 last | Sprint-plan P-42 correction | ✅ Fully |

### 5.4 Existing references that may break

`grep`-confirmed callers of `ConsentCheckboxes`:
- `lib/features/auth/presentation/screens/registration_form.dart` — uses public
  constructor only. Unchanged signature → ✅ safe.
- `test/features/auth/presentation/widgets/consent_checkboxes_test.dart` — uses
  public constructor. ✅ safe.
- No other files reference `_ConsentRow` (private) → ✅ free to refactor.

`grep`-confirmed callers of `_ReportButton` / `_InlineDismissButton`:
- Both are private to `scam_alert.dart` (`part of`). ✅ no external callers.

### 5.5 Design reference (UI tasks)

| Screen | Spec | Designs Reviewed | All l10n keys present? |
|:-------|:-----|:------------------|:------------------------|
| Registration (consent area) | `docs/screens/01-auth/02-registration.md` line 7 | Spec contemplates **one combined checkbox** ("Ik ga akkoord met de [Algemene voorwaarden] en [Privacybeleid]"). Current implementation is **two separate** checkboxes. Decision documented (see L1 above). Designs: `docs/screens/01-auth/designs/registration_*.png` (light + dark + expanded) reviewed; both checkbox layouts are visually viable — light/dark tokens already correct after PR #155. | ✅ existing keys (`auth.terms_agree_prefix`, `auth.privacy_agree_prefix`, `auth.terms_link`, `auth.privacy_link`) used as-is; one new key (`error.url_open_failed`) added. |
| Chat thread (composer send button) | `docs/screens/06-chat/02-chat-thread.md` | Light spec correct; dark mode golden currently uses raw `white` icon → after fix uses `colorScheme.onPrimary`. Visually identical in light mode (orange button → white icon). In dark mode the orange button persists (`primary` is theme-stable) and `onPrimary` resolves to white → identical render. Net: zero visual diff in either theme. | ✅ existing `chat.sendA11y` already wired. |
| Listing detail (sold overlay) | `docs/screens/03-listings/04-listing-detail.md` | Sold-state design uses dark overlay with white VERKOCHT badge in both themes. Implementation matches — no design change needed. Just adding inline comment. | ✅ existing `listing_detail.soldBadge` already wired. |

## 6 · Implementation Steps

> Steps are ordered for **shortest blocking-time per commit** so each commit is
> atomically reviewable on its own. Every step has explicit `Verify:` criteria.

### Step 1 — l10n: add `error.url_open_failed` (foundation)

- **Files:** `assets/l10n/en-US.json`, `assets/l10n/nl-NL.json`
- **Action:** Insert into existing `error` namespace, alphabetically:
  - EN: `"url_open_failed": "Couldn't open the link — please try again."`
  - NL: `"url_open_failed": "Kon de link niet openen — probeer het opnieuw."`
- **Verify:**
  - `dart run scripts/check_quality.dart` passes (l10n parity check).
  - `test/core/l10n/strings_test.dart` (auto) confirms key exists in both locales.
- **Commit:** `feat(l10n): add error.url_open_failed for launchUrl failure SnackBar`

### Step 2 — H2 (P0): scam-alert button labels

- **File:** `lib/widgets/trust/scam_alert_actions.dart`
- **Action:** Add `label: 'scam_alert.report'.tr()` to `_ReportButton` `Semantics`
  and `label: 'scam_alert.dismiss'.tr()` to `_InlineDismissButton` `Semantics`.
  Both keys already exist (verified in `assets/l10n/*.json` `scam_alert` namespace).
- **Verify:**
  - `tester.getSemantics(find.byType(_ReportButton)).label` contains
    `scam_alert.report` (NL or EN substring).
  - Same for dismiss.
  - No visual diff (label is screen-reader only).
- **Commit:** `fix(a11y): P-42 H2 — add Semantics label to scam-alert buttons`

### Step 3 — H1 (P0) + M2 (P1) + M1, M4 (P2): consolidate `consent_checkboxes.dart` rewrite

- **File:** `lib/features/auth/presentation/widgets/consent_checkboxes.dart`
- **Actions (single commit, 4 changes):**
  1. **H1**: wrap `InkWell` child `Text` in `Padding(EdgeInsets.symmetric(vertical: 12))`
     → guarantees ≥ 44 dp vertical touch target (12 + ~20 text + 12 = 44).
  2. **M2**: convert the `onTap` to `async`, capture
     `final ok = await launchUrl(Uri.parse(linkUrl), mode: LaunchMode.externalApplication);`,
     and on `!ok && context.mounted` show `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('error.url_open_failed'.tr())))`.
  3. **M1**: remove `theme` from `_ConsentRow` constructor; read
     `final theme = Theme.of(context);` inside `build`.
  4. **M4**: convert `ConsentCheckboxes` to `StatelessWidget` (delete the
     `_ConsentCheckboxesState` class; move `build` into the widget). Public
     constructor is preserved bit-for-bit.
- **Verify:**
  - File still under `200` lines (CLAUDE.md §2.1).
  - `flutter analyze --fatal-infos` clean.
  - All 7 existing tests still pass without modification.
- **Commit:** `fix(a11y): P-42 H1+M1+M2+M4 — touch target, launchUrl mode, theme, stateless`

### Step 4 — Tests for #156

- **File:** `test/features/auth/presentation/widgets/consent_checkboxes_test.dart`
- **Actions (4 new tests):**
  - **H1 regression:** `expect(tester.getSize(find.byType(InkWell).first).height, greaterThanOrEqualTo(44))`.
  - **M3 semantic association:** with `tester.ensureSemantics()`, assert that the
    checkbox node's `label` (or composed merged label) contains the link text.
    If the assertion fails (semantic boundary issue from `Semantics(link:true)`),
    the contingency is to wrap `Wrap` in `MergeSemantics` — this *only* triggers
    a follow-up commit if the test reveals the gap.
  - **L2a + L2b:** install a `UrlLauncherPlatform` mock; tap each link; assert
    the captured URL equals `AppConstants.termsUrl` / `AppConstants.privacyUrl`
    AND the captured `LaunchMode` is `externalApplication`.
  - **L2c:** force the mock to return `false`; tap link; pump; assert
    `find.byType(SnackBar)` is `findsOneWidget` and contains the
    `error.url_open_failed` translation.
- **Verify:**
  - `flutter test test/features/auth/presentation/widgets/consent_checkboxes_test.dart` — all green.
  - File under 300 lines (CLAUDE.md §2.1).
  - `dart run scripts/check_new_code_coverage.dart` ≥ 80 % on changed source files.
- **Commit:** `test(a11y): P-42 M3+L2 — semantic association, URL launcher, SnackBar`

### Step 5 — H2 (verify-only): regression test for `parcel_shop_list_item`

- **File:** `test/features/shipping/presentation/widgets/parcel_shop_list_item_test.dart`
  (extend if exists, else create).
- **Action:** Add a single test asserting the rendered `Semantics` node has
  `button: true` and `label` contains the shop name and the localised
  "distance km" / open-status string. Locks the existing fix.
- **Verify:** test passes; no source file under `lib/features/shipping/` modified.
- **Commit:** `test(a11y): P-42 H2 — regression test for ParcelShopListItem semantic label`

### Step 6 — #158 file 1: chat composer dark-mode color

- **File:** `lib/features/messages/presentation/widgets/chat_message_composer.dart`
- **Action:** Replace the two `DeelmarktColors.white` references in `_SendButton`
  (icon `color`, spinner `valueColor`) with `Theme.of(context).colorScheme.onPrimary`.
  Keep `bgColor` as `DeelmarktColors.primary` (theme-stable token).
- **Verify:**
  - Light-mode golden unchanged (white on orange).
  - Dark-mode golden unchanged (white on orange — `onPrimary` resolves to `white`
    against `primary` orange in both themes).
  - No diff in rendered output; semantic improvement only (forward-compat for any
    future theme change to `primary`).
- **Commit:** `fix(theme): P-47 follow-up — chat composer uses colorScheme.onPrimary`

### Step 7 — #158 file 2: sold-overlay dark-mode comment + golden

- **Files:**
  - `lib/features/listing_detail/presentation/widgets/sold_overlay.dart` (1-line comment).
  - `test/features/listing_detail/presentation/widgets/sold_overlay_test.dart`
    (golden test for dark mode).
- **Action:**
  - Add comment above the `BoxDecoration` color line: `// Intentional: overlay is theme-independent — neutral900 background + white text reads correctly in both themes.`
  - Add a `testWidgets('renders correctly in dark mode', (tester) async { ... })`
    using `MaterialApp(theme: ThemeData.dark())` and `expectLater` for golden.
- **Verify:** golden generated; visual review in PR confirms VERKOCHT badge legible.
- **Commit:** `test(theme): P-47 follow-up — verify SoldOverlay dark mode + add intent comment`

### Step 8 — Sprint-plan correction

- **File:** `docs/SPRINT-PLAN.md`
- **Action:** Change line 286 from
  ``- [ ] `P-42` Accessibility final audit — all screens WCAG 2.2 AA 🔄 PR #155 open (EAA blockers: issue #156)``
  to (after this PR is reviewed and merged):
  ``- [x] `P-42` Accessibility final audit — all screens WCAG 2.2 AA ✅ PRs #155 + this-PR (issue #156 closed)``.
  Also update the L3 reference: append `· Sprint plan re-marks P-42 ✅ once #156 closes.`
- **Verify:** sprint-plan diff is exactly **one line changed**.
- **Commit:** `docs(sprint): mark P-42 complete after #156 follow-up merge`

### Step 9 — Open follow-up issue for `splash_screen.dart` (cross-domain)

- **Action:** `gh issue create -t "chore(theme): migrate splash_screen.dart to colorScheme.surface" -l "enhancement,cross-domain" -a belengaz` with body referencing #158 file 3.
- **Rationale:** `lib/core/router/` is belengaz scope (CLAUDE.md L22). The current
  ternary works correctly; this is a polish suggestion, not a defect. Pizmam should
  not unilaterally edit core/router.
- **Verify:** issue link captured in PR description.
- **Commit:** none — issue creation is a side action.

### Step 10 — L1 spec/implementation alignment (combined-vs-separate consent)

- **File:** `docs/screens/01-auth/02-registration.md` (line 7).
- **Action:** Update the spec line to:
  ``7. **Terms checkboxes** — two separate checkboxes for GDPR Art. 7 granularity: "Ik ga akkoord met de [Algemene voorwaarden]" + "Ik ga akkoord met het [Privacybeleid]"``.
- **Rationale:** GDPR Art. 7 favours granular consent. The two-checkbox
  implementation is more defensible legally; the spec should follow.
- **Verify:** spec change is one line; design PNGs do not need to be regenerated
  (current designs already render two checkboxes).
- **Commit:** `docs(screens): align registration spec with two-checkbox consent (GDPR Art. 7)`

## 7 · Testing Strategy

| Layer | Tests Added / Touched | Coverage |
|:------|:----------------------|:---------|
| Widget — consent | 4 new (H1, M3, L2a, L2b, L2c) + 7 existing untouched | ≥ 80 % on changed widget |
| Widget — scam-alert | 1 new (H2 label assertion) | 100 % on changed file |
| Widget — parcel-shop | 1 new regression-only | Locks pre-existing fix |
| Widget — chat composer | Existing tests untouched; if golden regenerates, dark-mode golden updated | ≥ 80 % file-level |
| Widget — sold-overlay | 1 new dark-mode golden | 100 % file |
| L10n parity | Auto via `strings_test.dart` | 100 % keys |

**Mandatory commands before push (per CLAUDE.md §11):**

```bash
flutter analyze --no-pub --fatal-infos
dart run scripts/check_quality.dart
flutter test
dart run scripts/check_new_code_coverage.dart
```

All four MUST pass locally before pushing.

## 8 · Security Considerations

Reference: [`.claude/rules/security.md`](../.claude/rules/security.md), `docs/COMPLIANCE.md`.

| Concern | Status |
|:--------|:-------|
| **GDPR Art. 7 (informed consent)** | Hardened — M2 fix prevents silent failure of Terms/Privacy link, ensuring user has a real opportunity to read before consenting. |
| **Phishing via in-app WebView** | Hardened — `LaunchMode.externalApplication` forces system browser. |
| **WCAG 2.2 / EAA legal compliance** | Hardened — H1 + H2 close the two blocker categories (touch target, accessible name). |
| **Hardcoded credentials / secrets** | N/A — no secret-bearing files touched. |
| **SQL injection / XSS / CSRF** | N/A — no server-side surface, no user-input echo, no auth tokens. |
| **Rate-limiting** | N/A — UI-only changes. |
| **PII handling** | N/A — no new data flows. |

## 9 · Risks & Mitigations

| # | Risk | Severity | Mitigation |
|:--|:-----|:---------|:-----------|
| R1 | M3 semantic-association test fails because `Semantics(link:true)` creates a boundary preventing label composition. | Medium | Fall-back: wrap `Wrap` in `MergeSemantics`. Decision after seeing test result; one-line follow-up commit. |
| R2 | Golden regeneration cascade — chat composer color change causes goldens to invalidate even though render is bit-identical. | Low | If golden suite reports diff: regenerate via `flutter test --update-goldens`, eyeball the diff PNG, document in commit. |
| R3 | Cross-domain conflict if belengaz simultaneously edits `splash_screen.dart`. | Low | We do **not** touch this file in this PR. Open issue + assign to belengaz so changes don't collide. |
| R4 | L1 spec change opens a design discussion that delays merge. | Low | Spec change is in **a separate commit (Step 10)** so it can be cherry-removed at review time without losing the a11y fixes. |
| R5 | The worktree (`strange-lederberg`) is significantly behind `origin/dev` (10+ commits). Branching off worktree HEAD would lose recent fixes. | High | **Branch off `origin/dev` directly**: `git checkout -b feature/pizmam-a11y-darkmode-followup origin/dev`. Documented in §11 below. |
| R6 | New SnackBar in M2 may conflict with existing SnackBars on the registration screen (z-index / queueing). | Low | `ScaffoldMessenger` natively queues; visually verified during dev preview. |

## 10 · Architecture Impact

- **No new public APIs.** `ConsentCheckboxes` constructor is preserved.
- **Three private-widget changes** (one stateful→stateless, one constructor-param removal, one async callback). No downstream impact (no external consumers of private classes).
- **Two new tests files / extensions**, no new test infrastructure.
- **Two new l10n keys** (one effective, since both files share the namespace).
- **Zero migrations, zero Edge Functions, zero Riverpod providers.**

Component diagram (changed surface):

```
ConsentCheckboxes (StatelessWidget — was Stateful)
  └── _ConsentRow (Theme.of(context) internal — was passed)
        ├── Semantics(link: true)
        │     └── InkWell(onTap: launchUrl async w/ error SnackBar) ← H1+M2
        │           └── Padding(vertical: 12)                        ← H1
        │                 └── Text(linkKey)
        └── (existing CheckboxListTile structure unchanged)

scam_alert_actions.dart
  ├── _ReportButton → Semantics(button: true, label: scam_alert.report) ← H2
  └── _InlineDismissButton → Semantics(button: true, label: scam_alert.dismiss) ← H2

chat_message_composer.dart
  └── _SendButton (icon + spinner color: onPrimary) ← #158
```

## 11 · Branching, Rollback & Worktree Strategy

### Branching

```bash
# CRITICAL: branch off origin/dev, NOT off the strange-lederberg worktree HEAD
# (worktree is 10+ commits behind dev; branching off it loses PR #155, #157, #166).
git fetch origin dev
git checkout -b feature/pizmam-a11y-darkmode-followup origin/dev
```

### Rollback

Each step is its own commit. Reverting is `git revert <commit-hash>` per step:
- Revert Step 8 (sprint plan) without losing code fixes.
- Revert Step 6 (chat composer) without losing a11y fixes.
- Full PR revert: `git revert -m 1 <merge-commit>` rolls back atomically.

No DB migrations, no feature flags, no client cache invalidations needed.

## 12 · Observability

- No new logging, no new metrics, no new alerts.
- The `error.url_open_failed` SnackBar event could optionally be wired to
  `SentryFlutter.captureMessage('terms_link_launch_failed')` to detect a real
  outage. **Decision: defer to a separate observability epic** — adding Sentry
  hooks to a defect-fix PR widens scope and changes the commit type from `fix` to
  `fix + chore(observability)`.

## 13 · Performance Impact

- **Bundle size:** delta < 200 bytes (l10n strings + minor widget refactor).
- **Render perf:** `StatelessWidget` is marginally cheaper than `StatefulWidget`
  (no `State` allocation per build cycle).
- **Test runtime:** +5 widget tests ≈ 2 seconds added to suite.
- **Cold start:** unchanged.

## 14 · Documentation Updates

| Doc | Change | Step |
|:----|:-------|:-----|
| `docs/SPRINT-PLAN.md` | Re-mark P-42 `[x]` after #156 closes | Step 8 |
| `docs/screens/01-auth/02-registration.md` | Reword line 7 to reflect two-checkbox consent | Step 10 |
| Source comment in `sold_overlay.dart` | One-line "intentional" comment | Step 7 |
| GitHub issue (new) | Cross-domain `splash_screen.dart` polish for belengaz | Step 9 |
| `CHANGELOG.md` (if maintained) | One-line entry: "fix: WCAG 2.2 AA — touch target on consent links + scam-alert screen-reader labels" | Conditional — only if CHANGELOG exists; verified via grep before commit |

## 15 · Dependencies

### Blocks this work
- Nothing. All inputs available; no upstream PR or external dependency.

### Blocked by this work
- Sprint-plan P-42 truthfulness (Step 8 is the deliverable).
- #156 closure (this PR's merge auto-closes via "Closes #156" in PR body).
- #158 closure (this PR's merge auto-closes via "Closes #158" in PR body — except
  the splash_screen item, which moves to a new follow-up issue).

## 16 · Alternatives Considered

| Alternative | Why rejected |
|:------------|:-------------|
| **Split into 2 PRs (#156 fix + #158 fix)** | Issues are intertwined — #158 explicitly demands the sprint-plan correction that depends on #156 closing. Splitting forces sequential merges and re-states the same context twice. Single PR is shorter to review (≤ 500 LOC) and shorter to ship. |
| **Also fix `splash_screen.dart` here (one-line change)** | `lib/core/router/` is belengaz domain (CLAUDE.md L22). Unilateral edits violate ownership rules even for trivial changes. Open follow-up issue instead — minutes of belengaz time saves trust. |
| **Convert spec to one combined checkbox (Step 10 alternative)** | GDPR Art. 7 (a) requires consent be "specific" — combining Terms + Privacy into one tick weakens the consent record. Recommendation rejected by privacy-engineering principle. |
| **Skip M3 semantic-association test (because it might reveal a gap requiring more work)** | The whole point of the test is to *expose* the gap. If it passes, we're done; if it fails, fix is one line (`MergeSemantics` wrap). Skipping ships latent EAA risk. |
| **Use `common.url_open_failed` namespace instead of `error.url_open_failed`** | `error.*` namespace already exists with sibling keys (`error.network`, `error.payment_failed`); no `common` namespace exists. Convention match wins. |

## 17 · Success Criteria

This PR is "done" when **all** of the following are true:

- [ ] `flutter analyze --fatal-infos` returns 0 warnings.
- [ ] `flutter test` — all tests pass, including the 6 new ones.
- [ ] `dart run scripts/check_quality.dart` — 0 violations.
- [ ] `dart run scripts/check_new_code_coverage.dart` — ≥ 80 % on every changed source file.
- [ ] `dart run scripts/check_quality.dart --thorough` — no new SonarCloud-class warnings.
- [ ] Manual smoke test on iOS simulator + Android emulator: tap each Terms / Privacy link → opens in Safari / Chrome (not in-app WebView). Disable network → SnackBar appears with "Couldn't open the link…" / "Kon de link niet openen…".
- [ ] Manual VoiceOver test on iOS sim: scam-alert dismiss button announces "Verberg" / "Dismiss" (not just "button").
- [ ] Manual TalkBack test on Android sim: same as above.
- [ ] PR description references "Closes #156" and "Closes #158".
- [ ] PR size < 500 LOC (CLAUDE.md §Conflict Prevention).
- [ ] All 4 CI checks green (lint, analyze, test, SonarCloud).
- [ ] One reviewer approval from `belengaz` or `reso` (CLAUDE.md §Conflict Prevention "1 review from another dev").
- [ ] Follow-up issue for `splash_screen.dart` opened and linked from PR body.
- [ ] After merge: `docs/SPRINT-PLAN.md` line 286 reads `[x]` and references this PR.

## 18 · Alignment Verification

| Check | Question | Verdict |
|:------|:---------|:--------|
| Operating Constraints | Does this respect Trust > Optimization? | ✅ Yes — every change increases trust signals (legal compliance, screen-reader access, link transparency) without any optimization shortcut. |
| Existing Patterns | Does this follow project conventions? | ✅ Yes — uses `Theme.of(context)`, `Semantics(label:)`, `error.*` l10n namespace, `LaunchMode.externalApplication`, `colorScheme.onPrimary`. All idioms already present in codebase. |
| Rules Consulted | Which rule files were reviewed? | `CLAUDE.md` §1, §2.1, §3, §6, §7.1, §10, §11. `docs/design-system/accessibility.md`. `docs/design-system/tokens.md`. `docs/COMPLIANCE.md` (GDPR Art. 7). `~/.claude/rules/coding-style.md` (immutability — N/A; widget tree is rebuilt declaratively). `~/.claude/rules/security.md` (consent flow). `~/.claude/rules/testing.md` (80 % coverage, TDD ordering of Step 4 after Step 3). |
| Coding Style | Complies with `coding-style.md`? | ✅ Yes — files stay under §2.1 limits (consent_checkboxes < 200, test < 300), no mutation, no `setState`, no `FutureBuilder`, no `console.log`-equivalents. |
| Domain ownership | Respect §Reso/Belengaz/Pizmam scopes? | ✅ Yes — touches only pizmam-owned domains (`lib/features/auth/...widgets/`, `lib/widgets/`, `lib/features/messages/.../widgets/`, `lib/features/listing_detail/.../widgets/`, `assets/l10n/`, `test/`, `docs/`). Does **not** touch belengaz's `lib/core/router/` (deferred via Step 9). Does **not** modify any reso-owned source. |

## 19 · Plan Quality Self-Score (per `plan-schema.md`)

**Task size classification:** Medium (5–7 source files + tests + docs + l10n; 1–4h effort).
**Required tiers:** Tier 1 (60 pts) + Tier 2 (20 pts) = 80 pts max.

| § | Section | Pts Possible | Pts Awarded | Justification |
|:--|:--------|:-------------|:-------------|:--------------|
| 1 | Context & Problem Statement | 10 | 10 | 3 paragraphs covering problem, impact, motivation. |
| 2 | Goals & Non-Goals | 10 | 10 | 6 goals, 6 non-goals. |
| 3 | Implementation Steps | 10 | 10 | 10 steps, every one with file path + Verify. |
| 4 | Testing Strategy | 10 | 10 | Per-layer table + mandatory commands. |
| 5 | Security Considerations | 10 | 10 | 7 concerns assessed. |
| 6 | Risks & Mitigations | 5 | 5 | 6 risks with severity + mitigation. |
| 7 | Success Criteria | 5 | 5 | 12 verifiable checkboxes. |
| 8 | Architecture Impact | 4 | 4 | Diagram + explicit "no API change" statement. |
| 9 | API / Data Model Changes | 3 | 3 | Explicit "N/A — no DB / no Riverpod / no Edge Function". |
| 10 | Rollback Strategy | 3 | 3 | Per-commit revert + full PR revert documented. |
| 11 | Observability | 2 | 2 | Decision documented (deferred Sentry hook). |
| 12 | Performance Impact | 2 | 2 | Bundle, render, test, cold-start covered. |
| 13 | Documentation Updates | 2 | 2 | 5 docs identified, conditional CHANGELOG. |
| 14 | Dependencies | 2 | 2 | Both directions covered. |
| 15 | Alternatives Considered | 2 | 2 | 5 alternatives rejected with reasoning. |

**Domain bonus** (matched: a11y / dark-mode / l10n — all `frontend` domain):
- Frontend domain enhancer present (component diagram, design-reference table, l10n parity, golden tests): **+2**.

**Total score:** 80 / 80 + 2 bonus = **82 / 80 (102 %)** — **PASS** (well above 64-pt 80 % threshold).

---

## Approval Required

**To proceed to implementation**, please confirm:

1. ✅ Combined #156 + #158 single-PR scope is acceptable.
2. ✅ Splash-screen deferral via follow-up issue is acceptable (cross-domain respect).
3. ✅ L1 spec change (Step 10) — choosing two-checkbox over combined is acceptable.
4. ✅ Branch off `origin/dev` (not the worktree HEAD) is acceptable.

After approval, the implementation proceeds via `/implement` (or sequential tool
calls), one commit per Step, with `flutter analyze` + `flutter test` after each.
