# PLAN v2 — Tier-1 Audit (round 2)

> **Auditor:** Senior Staff Engineer (Claude, pizmam seat) · **Date:** 2026-04-17
> **Target:** [PLAN-pizmam-open-issues.md](PLAN-pizmam-open-issues.md) v2 @ SHA `HEAD`
> **Prior audit:** [PLAN-pizmam-open-issues-AUDIT.md](PLAN-pizmam-open-issues-AUDIT.md) (C1–C6, M1–M11)
> **Scope:** verify closure of v1 findings + surface new gaps introduced by revision + validate ADR coverage

## 0 · Executive summary

Plan v2 closes **6/6 CRITICAL** and **10/11 MAJOR** findings from audit v1 via ADRs 022–025, merge-DAG, locked Socratic decisions, fail-closed defaults, and flag-gating. Residual gaps are **tooling/artefact assumptions** that the plan treats as "already in tree" but aren't. None are legal-grade. Verdict: **CONDITIONAL PASS** — ship the zero-dependency work (Task C, D0, PR-0) in parallel with closing the artefact gaps listed in §2.

Self-score of plan: **42/50 (84%)** — below the plan's self-reported 94% because of the artefact misrepresentations in §2 below.

---

## 1 · V1 finding closure matrix

| ID | Severity | V1 finding | V2 resolution | Status |
|:--:|:--------:|:-----------|:--------------|:------:|
| C1 | CRIT | Client-side escrow derivation → EU consumer-law liability | ADR-023 backend-authoritative + checkout re-validate + fail-closed DTO + Unleash gate | ✅ closed |
| C2 | CRIT | Flutter Web CORS untested | §4.A.0 curl pre-flight, artefact `docs/verifications/cdn-cors.md`, weekly CI job | ⚠ closed-by-plan (artefact dir not yet created — see N1) |
| C3 | CRIT | No feature flag on trust badge | `listings_escrow_badge` flag + rollout stages in `docs/FEATURE-FLAGS.md` | ⚠ closed-by-plan (FEATURE-FLAGS.md not yet created — see N2) |
| C4 | CRIT | 10 sentinel false-positives treated as real Sonar issues | ADR-025 + Task D0 allowlist (replaces 3-day D1) | ✅ closed |
| C5 | CRIT | `cached_network_image` adopted without ADR | ADR-022 authored, accepted | ✅ closed |
| C6 | CRIT | ListingCard / DeelCard duplication | ADR-024 + PR-0 consolidation (blocker before A, B) | ✅ closed |
| M1 | MAJ | Semantics-tree regressions in refactors | D2–D5 DoD adds a11y-diff helper `test/helpers/a11y_diff.dart` | ⚠ helper file not yet created |
| M2 | MAJ | Unbounded Cloudinary egress | `f_auto,q_auto,w_{n}` + disk cache + 50 MB ceiling (ADR-022) | ✅ closed |
| M3 | MAJ | Memory not sized | Q2 locked: 200 objects / 50 MB decoded ceiling | ✅ closed |
| M4 | MAJ | Merge-dependency unordered | §0.6 DAG explicit | ✅ closed |
| M5 | MAJ | Extracted widgets lack smoke tests | D-PR DoD adds light+dark smoke per widget | ✅ closed |
| M6 | MAJ | Golden tolerance absent | Plan cites `test/helpers/tolerant_golden_comparator.dart` as **existing** | ❌ **STILL OPEN** — file does **not** exist on `origin/dev` (see F1) |
| M7 | MAJ | `original_price_cents` DB column unspecified | Q5 locked: open `[R]` tracking issue, keep fwd-compat DTO | ✅ closed |
| M8 | MAJ | Perf baseline procedure undefined | `scripts/perf_baseline.sh` "create if missing" | ⚠ script not yet created (see N3) |
| M9 | MAJ | WCAG diff not automated | Handled under M1 | see M1 |
| M10 | MAJ | Execution calendar too tight | ±20% buffer added, 5.5 → 9 days | ✅ closed |
| M11 | MAJ | Legal sign-off gating unclear | §3.3 row: "sign-off required > 10% rollout" | ✅ closed |

**Score:** C 6/6 closed, M 8/11 closed + 3 closed-by-paper. Net: all v1 blockers downgraded to documentation hygiene.

---

## 2 · NEW findings (introduced by v2 revision)

### F1 · MAJOR — `tolerant_golden_comparator.dart` claimed present, is absent

**Where:** PLAN v2 §4.A.2 step 7 and §4.D delta table both state "already in tree" / "already exists" referring to `test/helpers/tolerant_golden_comparator.dart`.

**Reality:** `test/helpers/` contains only `a11y_touch_target_utils.dart`, `a11y_visual_utils.dart`, `pump_app.dart`. No tolerant comparator.

**Impact:** M6 is not actually closed. First D-PR golden regen will hit brittle pixel-exact comparison; CI will flake on macOS vs Linux font-hinting (the cause SPRINT-PLAN already cites for repeated `chore(screenshots): regenerate shipping_qr golden for macOS rendering` commits — see `git log` 0b2b6fa, 14ae559).

**Fix:** Add PR-0 Step 6 — create `test/helpers/tolerant_golden_comparator.dart` using `flutter_test`'s `LocalFileComparator` subclass with RGB-distance tolerance (1% default). 30-line helper; reference pattern: flutter/flutter goldens toolkit. Block PR-0 DoD on this.

### F2 · MAJOR — `docs/verifications/` and `FEATURE-FLAGS.md` referenced as sinks but not in DoD

**Where:** PLAN §4.A.0, §4.B.2 step 7, §3.3, §4.A.3 "Docs" row.

**Reality:** Neither directory nor file exists. The plan treats them as destinations for artefacts but does not include their creation in any Task DoD.

**Impact:** Implementer may merge without committing CORS artefact or flag registry → audit-trail gap for legal/compliance.

**Fix:** Task A DoD explicit: "First line of `docs/verifications/cdn-cors.md` committed" and "`docs/FEATURE-FLAGS.md` exists with `listings_escrow_badge` row". Add a §13.5 governance note to CLAUDE.md placing these files under the marketing-asset guardrail (trust claims). Suggest `architect` + `doc-updater` co-review.

### F3 · MINOR — `scripts/web_smoke.sh` referenced, not created

**Where:** PLAN §4.A.2 step 8.

**Reality:** Does not exist; plan does not list it as a "create if missing".

**Impact:** First implementer must improvise; Web CORS bug could land silently.

**Fix:** PR-0 or Task A prerequisite: author minimal `scripts/web_smoke.sh` that runs `flutter build web --release --base-href=/`, serves via `dart pub global run dhttpd -p 8000 -a localhost build/web`, opens Chrome headless, asserts 200 on `/`, greps console for `CORS`. 40 lines.

### F4 · MINOR — Unleash `FeatureFlags.escrowBadge` API not verified

**Where:** PLAN §4.B.2 step 5 code sample assumes a `FeatureFlags` abstraction and `flags.escrowBadge` getter.

**Reality:** Repo has `lib/core/services/unleash_service.dart` (method signature unverified in plan). No wrapper `FeatureFlags` type exists — call-sites use `unleashService.isEnabled('flag_name')` directly.

**Impact:** Plan code sample will not compile as written. Minor, but violates §7.1 "Existing UI/logic scan".

**Fix:** Plan §4.B.2 step 5 rewrite: `listing.isEscrowAvailable && ref.watch(unleashServiceProvider).isEnabled('listings_escrow_badge')`. Or author `FeatureFlags` facade (Senior Staff call — defer; direct call is fine for now).

### F5 · MINOR — Merge-DAG omits Task D0 and Task C

**Where:** §0.6 DAG only shows PR-0, Task A, Task B, and D2–D5 cluster.

**Reality:** Task C (issue #100 close-out) and Task D0 (sentinel allowlist) have zero dependencies — belong in DAG as "can-ship-any-time" island.

**Fix:** Add "free-running" island node to DAG. Clarifies parallelism for orchestration.

### F6 · MINOR — Retrospective trigger under-specified

**Where:** §4.D delta table: "Retrospective `/retrospective` runs after the last D-PR merges".

**Reality:** No owner, no artefact path, no cadence. Plan should point to `docs/RETRO-*.md` file pattern (this audit adopts `docs/RETRO-pizmam-sprint-audit.md` as sibling).

**Fix:** §4.D DoD: "Retrospective author: pizmam. Artefact: `docs/RETRO-pizmam-E06-polish.md`. Trigger: last D-PR merge. SLA: 48h after merge."

### F7 · INFO — Self-score inflation ignores artefact debt

Plan self-scores 47/50 (94%). Independent score: **42/50 (84%)**. Differences: **Verification criteria** −2 (F1, F3), **Mandatory-rule extraction** −1 (F2 governance), **Specificity** −2 (F4, F5, F6).

This is the **same class** of inflation flagged in audit v1 (v1 self-reported 39/40 → audited to 82.5%). Pattern indicates plan author (this agent, pizmam seat) has a consistent +10pp optimism bias. Recommend: all future self-scores halved-then-averaged with audit.

---

## 3 · ADR coverage validation

| ADR | Decision quality | Rollback clarity | Scope fit | Audit verdict |
|:----|:----------------:|:----------------:|:---------:|:--------------|
| 022 (image pipeline) | ★★★★★ | ★★★★★ | ★★★★★ | **Accept.** Identical-API rollback, observability built-in. |
| 023 (escrow authority) | ★★★★★ | ★★★★★ | ★★★★★ | **Accept.** Legal reasoning cites CRD Art. 6(1)(r) + Omnibus 2019/2161 + ACM — tight. Fail-closed × flag × checkout re-validate is defense-in-depth. |
| 024 (card consolidation) | ★★★★☆ | ★★★★★ | ★★★★★ | **Accept with note.** `prefer_relative_imports: false` line in Step 4 is a non-sequitur — should be removed or moved to a separate lint-hygiene task. |
| 025 (copyWith sentinel) | ★★★★★ | ★★★★★ | ★★★★★ | **Accept.** Time-boxed with explicit review trigger; exactly the pattern CLAUDE.md §3.1 contemplates. |

---

## 4 · Residual risks not covered in plan §5

| # | Risk | L | I | Recommendation |
|:-:|:-----|:-:|:-:|:---------------|
| AR1 | `flutter_cache_manager` transitively pulls `sqflite` which requires iOS/macOS platform setup pods — can break existing mobile release builds if `Podfile.lock` stale | L | H | Add to Task A Step 2: `cd ios && pod install` smoke + CI matrix confirms iOS build. |
| AR2 | Cloudinary `f_auto,q_auto` negotiates AVIF/WebP — Flutter on older iOS WebViews may choke | L | M | Spec `w_{n},c_limit,f_auto,q_auto,fl_progressive`; defer AVIF via `fl_progressive` fallback. |
| AR3 | Unleash flag evaluation is **synchronous** in current service (confirm by reading `unleash_service.dart`) — if it blocks rebuilds, scroll jank | L | M | Task B: ensure flag read is behind a provider that caches; do not read in hot widget build. |
| AR4 | ADR-023 trigger recomputes on every `UPDATE` → possible recursive trigger loop if trigger itself updates `updated_at` | L | H | reso's migration PR must include trigger-loop-prevention (use `IS DISTINCT FROM` guard). Add to the `[R]` tracking-issue body. |

---

## 5 · Go/No-go per work item

| Item | Go? | Conditions |
|:-----|:---:|:-----------|
| Task C (#100 close-out) | 🟢 GO | None |
| Task D0 (sentinel allowlist) | 🟢 GO | None |
| PR-0 (card consolidation) | 🟡 GO with F1+F3 prereqs | Create `tolerant_golden_comparator.dart` + `scripts/web_smoke.sh` in PR-0 |
| Task A (#60 cached image) | 🟡 GO with F2 DoD additions | Commit CORS artefact + FEATURE-FLAGS.md skeleton |
| Task B (#59 escrow badge) | 🔴 HOLD | Blocked on reso migration + DTO + Unleash flag; rewrite §4.B.2 step 5 per F4 |
| Tasks D2–D5 | 🟡 GO after PR-0 | Requires tolerant comparator + a11y_diff helper |

---

## 6 · Recommended edits to PLAN v2 before `/implement`

1. **§0.6 DAG:** add "free-running island" with Task C + Task D0.
2. **PR-0 new Step 6:** create `test/helpers/tolerant_golden_comparator.dart` + test. Add to DoD.
3. **PR-0 new Step 7:** create `scripts/web_smoke.sh`. Add to DoD.
4. **Task A DoD:** add explicit lines for `docs/verifications/cdn-cors.md` and `docs/FEATURE-FLAGS.md` artefact creation.
5. **Task A §4.A.3 Testing:** add `cd ios && pod install` smoke (AR1).
6. **Task B §4.B.2 step 5:** fix `FeatureFlags.escrowBadge` → direct `unleashService.isEnabled(...)` call; verify via unleash_service read.
7. **ADR-024 Step 4:** remove dangling `prefer_relative_imports: false` note OR split to separate lint-hygiene task.
8. **§4.D delta table:** name retrospective artefact path + SLA.
9. **§9 self-score:** recompute as 42/50 (84%) honestly; retain dimension breakdown.

Apply 1–9 before `/implement` fires. None require architectural change.

---

## 7 · Closing statement

Plan v2 is a substantive, legally defensible, and architecturally coherent upgrade over v1. The remaining gaps are **execution hygiene** (artefacts, self-score honesty) rather than decision errors. The Senior Staff-level decisions (ADR-023 backend-authoritative, ADR-022 bounded cache, ADR-024 consolidation-before-feature) are the correct calls and would pass production review at a Tier-1 shop.

**Proceed** with Task C + Task D0 immediately. **Proceed** with PR-0 once §6 items 2–3 are absorbed. Task B remains blocked on reso by design.

> End of AUDIT v2.
