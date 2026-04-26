# P-54 PR Description Template

> Copy this block as the description of every P-54 PR. Delete sections that do not apply (e.g. "Mollie rollout" outside of PR-A).
> Plan: `docs/PLAN-P54-screen-decomposition.md`

---

## Scope

**PR ID:** PR-_TBD_ (e.g. PR-C, PR-D1, PR-A)
**Files touched (LOC delta):**
- `lib/.../foo_screen.dart` _(_OLD → NEW)_
- `lib/.../widgets/foo_section.dart` _(NEW)_

**Risk tier:** LOW / MED / HIGH / CRITICAL
**Closes:** P-54 task `<file_name>`; CLAUDE.md §2.1 budget breach

## Decomposition rationale (per D11/D24)

| Block extracted | Reason | Block inlined | Reason |
|-----------------|--------|---------------|--------|
| `FooSection` | 35 LOC + 3 testable behaviours | `_trustBanner` | 12 LOC, 0 callbacks |

## Forbidden-modification audit (§3.5)

- [ ] No public widget renamed
- [ ] No `Key` assignments changed on AnimatedSwitcher / Hero / List children
- [ ] No `const` ↔ non-`const` constructor flips
- [ ] No public `Notifier` / `Repository` signature changes
- [ ] No l10n keys renamed or removed
- [ ] No theme tokens swapped (colors / spacing / typography / radius)
- [ ] No `RepaintBoundary` / `KeyedSubtree` added or removed
- [ ] No `IndexedStack` / `Offstage` index ordering changes

## Definition of Done (per plan §13)

### Core gates (all PRs)
- [ ] `flutter analyze --fatal-infos` — zero warnings
- [ ] All target files ≤ 200 LOC
- [ ] All extracted sub-widget files ≤ 200 LOC
- [ ] All new test files ≤ 300 LOC
- [ ] `flutter test --concurrency=4` — 100% pass, zero new `skip:true`
- [ ] **Coverage by layer (D18):**
  - [ ] Domain: 100% on changed lines
  - [ ] Data: ≥80%
  - [ ] Presentation stateful: ≥80%
  - [ ] Presentation pure UI: ≥60%
- [ ] Goldens byte-identical OR ≤5% pixel diff with manual review note
- [ ] Goldens captured in both `nl-NL` + `en-US` (M3)
- [ ] Each commit individually green under `flutter test` (D9 bisect-safe)
- [ ] `check_quality.dart --all` zero violations
- [ ] `check_a11y.dart` zero violations
- [ ] CHANGELOG entry under Unreleased

### Conditional gates
- [ ] **PR-A (Mollie):** Unleash flag `mollie_checkout_v2` configured; rollout sequence documented (T+24h staging → T+48h 5% prod → T+1w 100% → T+2w flag remove)
- [ ] **PR-A (Mollie):** Sandbox iDEAL transactions complete (5 cases) — Sentry breadcrumb chain unchanged
- [ ] **PR-A (Mollie):** Coverage 100% on payment path
- [ ] **PR-A + PR-B:** P-56 trace baseline captured (7-day p50/p95/p99 dashboard screenshot)
- [ ] **PR-A + PR-B:** Manual VoiceOver / TalkBack pass — link/transcript in comment
- [ ] **PR-A + PR-B:** Mobile + web (canvasKit + html) renderer parity
- [ ] **PR-B + PR-D2:** DevTools memory snapshot pre/post — image pair attached

## Test additions

| File | Type | LOC | Coverage delta |
|------|------|-----|---------------:|
| `test/features/.../foo_section_test.dart` | smoke + Semantics + interaction | _N_ | +_X_% |

## Performance baseline (PR-A + PR-B + PR-D2 only)

P-56 trace: `<trace_name>`
- p50: _baseline_ → _post-merge_ (Δ_X_ms)
- p95: _baseline_ → _post-merge_ (Δ_X_ms, must be ≤ +10% or +0% ±100ms for `payment_create`)
- p99: _baseline_ → _post-merge_ (Δ_X_ms)

Dashboard screenshots: _attach_

## Memory baseline (PR-B + PR-D2 only)

Scenario: _e.g. open chat thread with 50 messages and scroll to top_
- Heap allocated: _pre_ MB → _post_ MB (Δ_X_%, must be ≤ +5%)
- Widget instances: _pre_ → _post_

DevTools screenshots: _attach_

## Reviewer matrix (D20 SLA)

- Primary reviewer: @_TBD_ (24h SLA on first review, 12h on revisions)
- Architecture spot-check: @MuBi2334 (reso) — for PR-D1, PR-F1, PR-A
- Payment co-review: @mahmutkaya (belengaz) — for PR-A only

Escalation: T+48h without primary review → ping @mahmutkaya in PR comment

## Hotfix readiness (per §11 L0/L3)

- Rollback path: L0 (forward-fix) / L1 (commit revert) / L2 (PR revert) / L3 (Unleash flip — PR-A only) / L4 (primitive flip — PR-D1 + PR-F1 only)
- On-call reviewer SLA for hotfix: 30 min
