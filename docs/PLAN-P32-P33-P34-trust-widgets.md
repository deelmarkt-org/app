# 📋 Plan — P-32 / P-33 / P-34 Trust & Chat Widgets

> **Owner:** pizmam (`[P]` — Frontend/Design)
> **Epics:** E01 Listing Management (P-32) · E03 Payments/Escrow (P-33) · E06 Trust & Moderation (P-34)
> **Sprint:** 5–8 (Weeks 9–16)
> **Workflows:** `.agent/workflows/plan.md`, `.agent/workflows/quality-gate.md`
> **Base:** `claude/funny-wing` → rebased onto `origin/dev`
> **Scope correction (2026-04-04):** P-31 `PriceTag` shipped via PR #66 (`feature/pizmam-P30-P31-gallery-pricetag`); this plan excludes it. P-34 `ScamAlert` added per sprint plan.

---

## 1. Socratic Gate — Confirmed

| # | Question | Answer |
|:-|:-|:-|
| 1 | Task set | **P-32 + P-33 + P-34** (P-31 already merged in PR #66) |
| 2 | P-33 EscrowTimeline already exists at `lib/widgets/trust/escrow_timeline.dart` with tests | **Audit + enhance** — already implemented on this branch, pending test verification, coverage check, and PR |
| 3 | Branch strategy | **One branch per task, three PRs** (≤ 500 lines each per §5.3) |
| 4 | Design sources | `docs/screens/03-listings/` (P-32) · `docs/screens/04-payments/` (P-33) · `docs/screens/06-chat/` (P-34) per `memory/feedback_ui_design_sources.md` |
| 5 | Sync rule | Rebase every branch onto `origin/dev` before starting (per `memory/feedback_sync_before_work.md`) |

---

## 2. Global Scope & Non-Goals

### In scope
- **P-32** — Promote `ListingLocationRow` → shared `LocationBadge` under `lib/widgets/location/` with compact/detail/skeleton variants, migrate call sites, delete feature-local file (CLAUDE.md §3.1).
- **P-33** — Audit existing `EscrowTimeline` against reference designs; fix 9 gaps (off-path states, dark mode, deadline countdown, narrow-screen, tap targets, Semantics button, pulse animation); bring to 100% coverage per §6.1.
- **P-34** — Net-new `ScamAlert` widget (inline chat banner) with high/low-confidence variants, expandable reason, Report action; four reference states from `docs/screens/06-chat/designs/`.
- Localisation keys (NL + EN) for every new string.
- Widget + golden tests for every new/enhanced file.
- No new screens — widgets + wiring updates only.

### Out of scope
- Backend / data layer changes (`[R]` owns)
- Routing changes (`[B]` owns)
- The chat thread screen itself (P-36 in sprint plan — future task)
- Backend scam-detection Edge Function (R-35, reso owns)
- Mini-map preview inside `LocationBadge` — will ship as a placeholder rectangle; real map is B-31
- `Formatters.euroFromCents` / `distanceKm` / `shortDateTime` changes (already exist, correct Dutch locale)

---

## 3. Existing Code to Reuse (do NOT duplicate)

| Asset | Path | Reuse for |
|:-|:-|:-|
| `Formatters.distanceKm` | `lib/core/utils/formatters.dart:24` | `LocationBadge` distance text |
| `Formatters.shortDateTime` | `lib/core/utils/formatters.dart:43` | `EscrowTimeline.deadlineHint` (fix A4) |
| `DeelmarktColors.trust*`, `error*`, `warning*` | `lib/core/design_system/colors.dart` | `EscrowTimeline`, `ScamAlert` tonal backgrounds |
| `DeelmarktColors.darkTrust*`, `darkError*`, `darkWarning*` | same (new dark tokens already landed) | P-33 dark theme, P-34 dark theme |
| `Spacing.s*` / `DeelmarktRadius.*` | design_system | All layout |
| `SkeletonLoader` (P-07) | `lib/widgets/feedback/` | `LocationBadge.skeleton()` variant |
| `ListingLocationRow` | `lib/features/home/presentation/widgets/listing_location_row.dart` | Migrate callers, then delete |
| `EscrowStepCircle` + `EscrowConnectorPainter` | `lib/widgets/trust/escrow_step_circle.dart` | Enhanced in place on this branch |
| `TransactionStatus` enum | `lib/core/models/transaction_status.dart` | Drives `computeEscrowTimelineState` mapper |
| `TrustBanner.warning`/`.info` | `lib/widgets/trust/trust_banner.dart` | Reference style for `ScamAlert` (same tonal shell, different API surface) |
| `DeelButton` ghost/destructive variants | `lib/widgets/buttons/deel_button.dart` | `ScamAlert` action row (Report, Dismiss) |
| `PhosphorIcons.warning` / `.warningCircle` / `.shieldWarning` | `phosphor_flutter` package | `ScamAlert` icon |

---

## 4. Task P-32 — `LocationBadge`

**Branch:** `feature/pizmam-P32-location-badge`
**Refs:** `docs/design-system/components.md` (LocationBadge row), `docs/design-system/patterns.md` §Listing Detail, `docs/screens/03-listings/01-listing-detail.md` §Layout #6.

### 4.1 Why promote from feature-local
`ListingLocationRow` is imported today by `ListingCard` (home feature) and is required by `ListingDetailScreen` (listing_detail feature). CLAUDE.md §1.2 forbids cross-feature imports and §3.1 mandates shared widgets in `lib/widgets/`.

### 4.2 API
```dart
enum LocationBadgeVariant { compact, detail, skeleton }

class LocationBadge extends StatelessWidget {
  const LocationBadge({
    required this.city,
    this.distanceKm,
    this.postalCode,                  // Semantics only — never rendered (GDPR)
    this.variant = LocationBadgeVariant.compact,
    this.showMapPlaceholder = false,  // detail-only; not a real map (B-31 owns)
    this.onTap,
    super.key,
  });

  const LocationBadge.skeleton({super.key});
}
```

### 4.3 Files
| Action | Path | Lines ≤ |
|:-|:-|:-:|
| Create | `lib/widgets/location/location_badge.dart` | 200 |
| Create | `lib/widgets/location/location_badge_skeleton.dart` | 80 |
| Create | `test/widgets/location/location_badge_test.dart` | 300 |
| Modify | `lib/features/home/presentation/widgets/listing_card.dart` (swap `ListingLocationRow` for `LocationBadge(variant: compact)`) | — |
| **Delete** | `lib/features/home/presentation/widgets/listing_location_row.dart` after migration (verify with `grep`) | — |
| Modify | `assets/l10n/nl-NL.json` + `en-US.json` → `location_badge.a11yWithDistance`, `a11yCityOnly`, `mapPlaceholder` | — |

### 4.4 Rules
- Compact variant must be visually identical to today's output (minimises golden diff noise)
- Detail: pin 18 px, city `headlineSmall`, distance `bodyMedium` `neutral700`, optional 16:9 `neutral100` map placeholder with centred `mapPin` icon
- Tap target ≥ 44×44 when `onTap != null`
- `postalCode` never appears in a `Text` — asserted by widget test (GDPR)
- Distance formatted with `Formatters.distanceKm` (nl_NL locale, comma decimal)

### 4.5 Verification
- `flutter analyze` zero warnings
- `grep -rn "ListingLocationRow" lib/ test/` returns zero
- 10 golden tests (compact ± distance, detail ± map placeholder, skeleton) × light/dark
- Semantics snapshot verifies NL + EN strings
- Contrast check (P-12 tooling) — `onSurfaceVariant` on `surface` ≥ 4.5:1 both themes
- `listing_card` tests still green (update goldens intentionally if needed)

---

## 5. Task P-33 — `EscrowTimeline` audit + enhance  ✅ IN PROGRESS

**Branch:** `feature/pizmam-P33-escrow-timeline-polish` (current)
**Refs:** `docs/design-system/patterns.md` §Escrow Timeline, `docs/screens/04-payments/designs/transaction_detail_{paid,shipped,delivered,released}_{light,dark}/`, `docs/screens/04-payments/03-transaction-detail.md`.

### 5.1 Audit findings

| # | Sev | Finding | Fix | Status |
|:-|:-:|:-|:-|:-:|
| A1 | HIGH | Only 5 happy-path states handled; `disputed`/`refunded`/`resolved`/`cancelled`/`expired`/`failed`/`paymentPending`/`created` → entire timeline rendered as pending | Pure-Dart `computeEscrowTimelineState` mapper with explicit branches | ✅ Done |
| A2 | HIGH | Payment-path widget must be **100% coverage** (§6.1); existing tests cover happy path only | Unit-test mapper to 100%; expand widget tests | ✅ Done (29/29 mapper, 75/75 timeline, 88/88 step circle) |
| A3 | MED | Hardcoded colours → no dark-mode adaptation | `EscrowStepTone` enum (trust/warning/muted) + theme-aware pending border | ✅ Done |
| A4 | MED | `escrow.countdownHint` rendered without actual date | New `escrow.deadlineHint` key formatted with `Formatters.shortDateTime` | ✅ Done |
| A5 | MED | 5 labels in a Row clip below 360 px | `LayoutBuilder` narrow breakpoint → 2-line wrap at `labelSmall` 10 px | ✅ Done |
| A6 | LOW | Inconsistent tap target | `ConstrainedBox(minHeight: 44)` + `InkWell` | ✅ Done |
| A7 | LOW | No `Semantics(button: true)` when `onStepTapped` set | Conditional flag | ✅ Done |
| A8 | LOW | Missing pulse animation; wrong colour token (primary instead of trustEscrow) | `AnimationController` repeat, respects `MediaQuery.disableAnimations` | ✅ Done |
| A9 | LOW | Test helper `pumpTestWidget`/`pumpTestScreen` starved `pumpAndSettle` with the new pulse | Disable animations in `test/helpers/pump_app.dart` (applies to all 35 callers) | ✅ Done |

### 5.2 Files changed on current branch

| Action | Path | Status |
|:-|:-|:-:|
| Create | `lib/widgets/trust/escrow_timeline_state.dart` (pure Dart mapper) | ✅ |
| Create | `test/widgets/trust/escrow_timeline_state_test.dart` | ✅ |
| Modify | `lib/widgets/trust/escrow_timeline.dart` | ✅ |
| Modify | `lib/widgets/trust/escrow_step_circle.dart` | ✅ |
| Modify | `test/widgets/trust/escrow_timeline_test.dart` | ✅ |
| Modify | `test/widgets/trust/escrow_step_circle_test.dart` | ✅ |
| Modify | `test/helpers/pump_app.dart` (animation-disabled wrappers) | ✅ |
| Modify | `assets/l10n/nl-NL.json` + `en-US.json` (`deadlineHint`, `disputed`, `cancelled`, `terminalRefunded`, `terminalResolved`) | ✅ |

### 5.3 Remaining P-33 steps
- [ ] Run `flutter test` across all affected suites (trust widgets, transaction feature, other pumpTestScreen callers) — confirm no regression from the pump helper change
- [ ] `flutter analyze` — zero warnings (scoped to my diff; pre-existing `lib/main.dart` + `test/features/sell/**` errors on `dev` are not in scope)
- [ ] Coverage re-run: confirm 100% on both `escrow_timeline*` files
- [ ] Flip `P-33` checkbox in `docs/SPRINT-PLAN.md`
- [ ] Commit `feat(widgets): harden EscrowTimeline states, theming, a11y (P-33)`
- [ ] Open PR, run `code-reviewer` + `security-reviewer` agents

### 5.4 Risks
- **Pre-existing compile errors on `dev`** (`supabaseClientProvider`, `listingCreationNotifierProvider`) — not in scope; must not attempt to fix (ownership + blast radius). CI behaviour on PR may differ; confirm after pushing.
- Pulse animation on low-end Android — mitigated by `disableAnimations` honoured and `AnimationController` stops when `isActive` goes false.
- Theme-aware refactor could ripple to `trust_banner.dart` — only additive tone enum introduced; existing tokens untouched.

---

## 6. Task P-34 — `ScamAlert` (new)

**Branch:** `feature/pizmam-P34-scam-alert`
**Refs:**
- `docs/design-system/patterns.md` §Scam Alert (Inline)
- `docs/screens/06-chat/03-scam-alert.md`
- `docs/screens/06-chat/designs/scam_alert_high_confidence_light_mobile/`
- `docs/screens/06-chat/designs/scam_alert_high_confidence_dark_mobile/`
- `docs/screens/06-chat/designs/scam_alert_low_confidence_light_mobile/`
- `docs/screens/06-chat/designs/scam_alert_expanded_reason_desktop_light/`

### 6.1 Purpose
Inline chat banner rendered above a suspicious message bubble. Four visual contracts from the reference designs:
1. **High-confidence light** — `errorSurface` bg, `trustWarning` 3 px left border, warning-triangle icon, non-dismissible, Report action.
2. **High-confidence dark** — same structure, `darkErrorSurface` + `darkTrustWarning`.
3. **Low-confidence** — `warningSurface` bg, `trustPending` left border, dismissible (shows "Negeer" action).
4. **Expanded reason** — collapsible section reveals AI's detection rationale (e.g. "Bevat externe betaallink", "Telefoonnummer verzoek"), "Meld dit bericht" link remains visible.

### 6.2 API

```dart
enum ScamAlertConfidence { high, low }

enum ScamAlertReason {
  externalPaymentLink,
  phoneNumberRequest,
  offSiteContact,
  suspiciousPricing,
  other,
}

class ScamAlert extends StatefulWidget {
  const ScamAlert({
    required this.confidence,
    required this.reasons,      // rendered as a bullet list when expanded
    this.onReport,              // tapping "Meld verdacht" — required for high
    this.onDismiss,             // only invoked for low-confidence
    this.initiallyExpanded = false,
    super.key,
  });
}
```

- High-confidence banner has no dismiss button (enforced at build time by only rendering it when `onDismiss == null || confidence == ScamAlertConfidence.low`).
- "Waarom deze waarschuwing?" toggle flips an `AnimatedSize` + `AnimatedRotation` on the chevron.
- Reason strings come from `assets/l10n/*.json` via a reason → key map, never hard-coded.
- Semantics: single merged label summarising confidence + first reason; `Semantics(liveRegion: true)` so screen readers announce on first insertion.

### 6.3 Files

| Action | Path | Lines ≤ |
|:-|:-|:-:|
| Create | `lib/widgets/trust/scam_alert.dart` | 200 |
| Create | `lib/widgets/trust/scam_alert_reason.dart` (enum + l10n key map) | 60 |
| Create | `test/widgets/trust/scam_alert_test.dart` | 300 |
| Modify | `assets/l10n/nl-NL.json` → `scam_alert.title`, `scam_alert.reasonLabel`, `scam_alert.report`, `scam_alert.dismiss`, `scam_alert.whyWarning`, `scam_alert.reasons.{externalPaymentLink,phoneNumberRequest,offSiteContact,suspiciousPricing,other}` | — |
| Modify | `assets/l10n/en-US.json` → matching keys | — |

No feature code is modified — this is a net-new shared widget. Chat-thread integration is P-37 (a later task).

### 6.4 Rules
- Zero raw `Color(0xFF...)`, `TextStyle`, or strings (§3.3)
- Tokens: `errorSurface` / `darkErrorSurface` for high; `warningSurface` / `darkWarningSurface` for low; borders via `trustWarning` / `trustPending`
- Respect `MediaQuery.disableAnimations` for expand/collapse
- Contrast ≥ 4.5:1 for all text on both surfaces (WCAG 2.2 AA)
- Touch targets ≥ 44×44 for Report and Dismiss actions
- Non-dismissible constraint enforced both in API (assert) and visually (no button rendered)

### 6.5 Verification
- `flutter analyze` zero warnings
- 12 golden tests: {high/low} × {collapsed/expanded} × {light/dark} = 8, plus 4 edge cases (long reason text, zero reasons, multiple reasons, RTL)
- Unit tests for the enum → l10n key map (100%)
- Interaction tests: tap toggle expands; tap Report fires callback; tap Dismiss only possible in low-confidence path
- Semantics snapshot verifies live-region announcement and merged label
- No `onDismiss` invocations reachable when `confidence == high` — asserted
- `security-reviewer` agent pass (handles untrusted user input — message content never rendered inside the widget, only the flag reason)

### 6.6 Risks

| Risk | Mitigation |
|:-|:-|
| Reason strings drift from backend taxonomy (R-35) | Treat enum as source of truth locally; reso maps backend flags → enum before passing in. Document in widget docstring. |
| Expand/collapse animation breaks `pumpAndSettle` in downstream chat tests | Same pattern as P-33: use `AnimatedSize` (finite) + disableAnimations in test helpers |
| Golden count may push PR over 500 lines | Goldens are binary assets, count against repo size not PR LOC; still keep test file ≤ 300 lines by extracting fixture builders |

---

## 7. Delivery Order

```
P-33 (in progress) ─┐
                     ├─ ship sequentially to avoid rebase churn
P-32               ──┤
                     │
P-34 (new)         ──┘
```

1. **P-33** — finish tests + open PR (current session continues here)
2. **P-32** — after P-33 merges, rebase new branch onto `origin/dev`
3. **P-34** — after P-32 merges, rebase new branch onto `origin/dev`

---

## 8. Cross-Cutting Concerns

- **Security:** no user input parsing in P-32 or P-33; P-34 must never render raw message content — only the classifier reason.  `security-reviewer` agent runs on all three PRs. `detect-secrets` stays green.
- **Testing (§6):** TDD red-first; ≥ 70% coverage on new files; **100%** on P-33 payment-path files (enforced). Golden tests per variant × theme. `Formatters.initDateLocales()` in test `setUp` if dates involved.
- **A11y (§10):** NL + EN `Semantics` labels, ≥ 44×44 touch targets, ≥ 4.5:1 contrast, respect `disableAnimations`, text-scale up to 2.0, live-region announcement for P-34.
- **i18n:** every new string in `assets/l10n/*.json`, alphabetically sorted per CLAUDE.md conflict rules.
- **Docs:** inline `///` doctags reference `docs/design-system/components.md`. No new markdown files except this plan.  `P-32`/`P-33`/`P-34` checkboxes flipped in `docs/SPRINT-PLAN.md` on each merge per `memory/feedback_sprint_plan_auto_update.md`.
- **Git (§5):** rebase onto `origin/dev` before each PR; commit types `feat(widgets):` / `refactor(widgets):`; never `--no-verify`. Per `memory/feedback_git_bash_slash.md`, use `//` path prefix with `gh pr comment` on Windows.

---

## 9. Quality Gate (`.agent/workflows/quality-gate.md`)

| Gate | P-32 | P-33 | P-34 |
|:-|:-:|:-:|:-:|
| `dart format --set-exit-if-changed .` | ✅ | ✅ | ✅ |
| `flutter analyze` zero warnings (on diff) | ✅ | ✅ | ✅ |
| `flutter test` green (all suites that compile) | ✅ | ✅ | ✅ |
| Coverage ≥ 70% on touched files | ✅ | ✅ (100%) | ✅ |
| Golden tests per state × theme | ✅ | ✅ | ✅ |
| Semantics labels NL + EN | ✅ | ✅ | ✅ |
| No raw colour/string/spacing literals | ✅ | ✅ | ✅ |
| File length within §2.1 budget | ✅ | ✅ | ✅ |
| WCAG 2.2 AA contrast + 44×44 | ✅ | ✅ | ✅ |
| PR ≤ 500 lines | ✅ | ✅ | ✅ |
| `code-reviewer` agent clean (no HIGH) | ✅ | ✅ | ✅ |
| `security-reviewer` agent clean | ✅ | ✅ | ✅ |
| SonarCloud new-code duplication < 3% | ✅ | ✅ | ✅ |

---

## 10. Global Risks

| # | Risk | Sev | Mitigation |
|:-|:-|:-:|:-|
| 1 | Pre-existing compile errors on `dev` (`lib/main.dart`, `test/features/sell/**`) block full-suite CI | HIGH | Not in scope for `[P]`; flag on PR if CI fails; coordinate with `[R]` / `[B]` to fix root cause separately |
| 2 | Golden drift across three PRs | MED | Scope goldens per widget; commit regenerated goldens with visual proof in PR description |
| 3 | SonarCloud duplication across similar widget scaffolding | MED | Share enum/extension helpers; avoid copy-paste |
| 4 | Deletion of `ListingLocationRow` (P-32) collides with in-flight work on other `[P]` branches | MED | `git grep` on `origin/dev` before opening PR; coordinate on Slack |
| 5 | P-34 backend taxonomy (R-35) may change reason enum | MED | Document enum contract in widget docstring; backend → enum mapping lives outside this widget |
| 6 | Rebase conflicts during sequential delivery | LOW | Ship strictly sequentially; rebase onto latest `dev` before each PR |

---

## 11. Verification Commands

Per task, before opening PR:

```bash
dart format --set-exit-if-changed .
flutter analyze lib/widgets test/widgets    # scoped to my diff
flutter test test/widgets/trust test/widgets/location test/features/transaction --coverage
# P-33 coverage proof:
awk '/SF:lib.widgets.trust.(escrow_timeline|escrow_timeline_state|escrow_step_circle)/,/end_of_record/' coverage/lcov.info | grep -E "^LF|^LH"
# P-32 migration verification:
grep -rn "ListingLocationRow" lib/ test/    # must return zero
# P-34 safety verification:
grep -rn "Color(0xFF\|Text('⚠️\|fontSize:" lib/widgets/trust/scam_alert.dart  # must return zero
```

Visual verification:
- iPhone 15 Pro (390×844) + small Android (320×720) for P-33 narrow-screen label wrap
- System dark mode on/off → verify all three widgets swap surfaces
- "Reduce Motion" → verify P-33 pulse stops and P-34 expand is instant
- Walk `paid → shipped → delivered → confirmed → released` via mock data and compare each frame against `docs/screens/04-payments/designs/transaction_detail_{state}_light/screen.png`
- Render `ScamAlert` in high/low × expanded/collapsed × light/dark and compare against four reference designs

---

## 12. Retrospective Hook

After all three PRs merge, compare this plan against `git diff --name-only <plan-start-sha>..HEAD`, log surprises to `.agent/contexts/plan-quality-log.md`, and promote any repeating feedback to global memory (`feedback_*.md`). Update `docs/design-system/components.md` priority column if priorities shift.

---

**Quality self-score:** 88/100 (Tier: Medium; all mandatory sections populated; every task has file paths + verification criteria; cross-cutting concerns covered; P-33 progress tracked in-line; risks enumerated per task and globally).

**Status:** P-33 implementation is already complete on this branch and awaits final verification + PR. P-32 and P-34 are unstarted — scheduled after P-33 merges.
