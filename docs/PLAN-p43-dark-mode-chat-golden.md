# PLAN — P-43 Dark Mode Chat Thread Design Handoff + Golden Regeneration

> **Status:** ✅ **COMPLETED** — shipped via [PR #169](https://github.com/deelmarkt-org/app/pull/169) (merged 2026-04-23). Issue [#164](https://github.com/deelmarkt-org/app/issues/164) closed.
> _Doc preserved for historical reference. Acceptance items below were satisfied at merge time; PR review + CI is the source of truth._
>
> **Owner:** pizmam (`[P]`) — Frontend / Design
> **Epic:** E07 Infrastructure (launch readiness) · follow-up to E04 Messaging
> **Branch:** `feature/pizmam-P43-dark-mode-chat-golden` (created from `origin/dev`)
> **Parent PR (merged):** [#161](https://github.com/deelmarkt-org/app/pull/161) — ASO pipeline
> **Closes:** issue [#164](https://github.com/deelmarkt-org/app/issues/164) — Design handoff: dark mode chat thread golden PNG
> **Tier:** **Medium** (3–10 files across design references + goldens + docs)
> **Estimate:** 0.5 developer-day (no production `lib/` changes)
> **Produced via:** `.agent/workflows/plan.md` v2.2.0 (Specialist Synthesis + rule consultation)

---

## 1 · Context & Current-State Audit

### What merged (PR #161)
- 240 golden screenshots generated via `test/screenshots/drivers/` (10 hero screens × 2 locales × 2 themes × 6 devices).
- Dark-mode chat thread goldens **already exist** (24 files, e.g. [chat_thread_nl_NL_dark_ios_67.png](test/screenshots/drivers/goldens/chat_thread_nl_NL_dark_ios_67.png)) — captured against the running `ChatThreadScreen` widget in dark mode.
- Pixel diffing runs **only on macOS CI** ([screenshot_driver.dart:170](test/screenshots/_support/screenshot_driver.dart:170)); Linux/Windows pumps the widget but skips `expectLater(matchesGoldenFile)`.

### The blocker (issue #164)
- `docs/screens/06-chat/designs/` has **3 chat-thread design variants**:
  - `chat_thread_mobile_light/` ✅ (layout + copy source of truth)
  - `chat_thread_mobile_dark_scam_alert/` ✅ (dark base + red scam banner)
  - `chat_thread_desktop_expanded/` ✅
  - `chat_thread_mobile_dark/` ❌ **missing** — no "normal" dark variant design reference
- Consequence: the committed dark-mode goldens are a **snapshot of what the widget renders today**, with no design PNG to diff against. Any unintended dark-mode regression (wrong bubble tint, contrast drop on timestamps, etc.) would be invisible to reviewers.

### Why this matters (legal / conversion)
- **Dark mode is a CLAUDE.md §10 accessibility gate** — reduced-motion / dark-mode support is declared in spec [`02-chat-thread.md:16`](docs/screens/06-chat/02-chat-thread.md:16) as **Required**.
- **App Store Review guideline 4.0** expects parity between marketed screenshots and shipped UI. Screenshot regressions in the hero set delay submission.
- The existing `mahmutkaya` approving review on PR #161 explicitly tracked this as "M9 — tracked in issue #164, needs designer handoff noted in sprint plan." Shipping the reference closes the review loop.

### What is NOT in scope (guarded by scope filter)
- No changes to `ChatThreadScreen` widget or any `lib/` production code.
- No changes to l10n copy, design tokens, or theme.
- No changes to Fastlane / ASO metadata (guarded by CLAUDE.md §13 — marketing assets require explicit human approval).
- No regeneration of non-dark / non-chat_thread goldens.
- Scam-alert variant stays as-is; we are filling the gap for the "normal" dark variant only.

---

## 2 · Rule Consultation (mandatory — per plan.md step 3)

Extracted from CLAUDE.md and `~/.claude/rules/**`:

| Mandate | Source | Applies here as |
|:--------|:-------|:----------------|
| UI tasks require spec + design-reference verification block | CLAUDE.md §7.1 step 5 | Plan includes the `### Design reference` block (§7 below) |
| Design tokens only — no raw hex | CLAUDE.md §3.3, §4.3 | Derived dark-mode reference must only use `DeelmarktColors.dark*` values; HTML source uses the same MD3 palette as existing dark design |
| Marketing asset guardrail | CLAUDE.md §13 | `docs/screens/**` is NOT a marketing asset (marketing = `fastlane/metadata/**` and `docs/marketing/aso/**`) → safe to edit without §13 human approval, but still needs PR review |
| Pre-commit quality gates must pass | CLAUDE.md §8 | `flutter analyze`, `check_quality.dart`, screenshot PNG audit (`check_screenshots.sh`) all must stay green |
| 70%+ test coverage floor | CLAUDE.md §6.1 | N/A — no `lib/` code touched; coverage unaffected |
| Accessibility (WCAG 2.2 AA, EAA) | CLAUDE.md §10, `~/.claude/rules/security.md` | Dark-mode reference must maintain 4.5:1 contrast on message text, 3:1 on large text — verified by sampling |
| Immutability / file length / naming | `~/.claude/rules/coding-style.md` | N/A — no Dart changes |
| Design handoff protocol | `docs/screens/06-chat/02-chat-thread.md` | Dark mode listed as "Required" variation (line 16 + Design Prompt line 72) |

**Rejection triggers evaluated (quality-gate.md):** none fire. This is a design-deliverable close-out, not a new feature — no market research required.

---

## 3 · Specialist Synthesis (per planningMandates)

### 3.1 `security-reviewer` — Threat Assessment
| Threat | Mitigation | Test |
|:-------|:-----------|:-----|
| **PII leak via design reference** (real avatar, real Dutch phone number / address rendered into the PNG) | Reference HTML uses the **same fictitious persona** as the light variant: "Jan de Vries", Canyon Speedmax, `@example.invalid` seed data anchored in [`test/screenshots/_support/seed_data.dart`](test/screenshots/_support/seed_data.dart) | Manual inspection of generated PNG; existing `scripts/check_screenshots.sh` OCR PII scan covers the `goldens/` copy |
| **Tracking-pixel or remote asset in HTML** | Use local font/CSS only; no `<script src="http…">` to external trackers; match existing `chat_thread_mobile_light/code.html` structure | `grep -n "http://\|https://" docs/screens/06-chat/designs/chat_thread_mobile_dark/code.html` → allow-list: Google Fonts + Material Symbols CDNs only (same as existing) |
| **Secret leak in committed PNG metadata** | Strip EXIF / XMP from generated PNG via `pngcrush`/`exiftool` before commit | File size + metadata check (already in `check_screenshots.sh`) |

### 3.2 `tdd-guide` — Test & Verification Strategy
No new `lib/` code → no new unit / widget tests. Verification is **visual + automated asset-lint**:

| Verification | Command | Pass Criterion |
|:-------------|:--------|:---------------|
| Design PNG present | `ls docs/screens/06-chat/designs/chat_thread_mobile_dark/screen.png` | Exists |
| Design HTML valid | Open in browser; visually matches layout spec §02-chat-thread.md §1–6 | No layout break; matches existing light layout modulo palette |
| Golden regenerated (macOS CI) | `screenshots.yml` workflow on PR runs `flutter test --update-goldens test/screenshots/drivers/chat_thread_screenshot_test.dart` → auto-commits | All 24 dark-variant PNGs diff cleanly (or auto-updated by CI) |
| Screenshot count stable | `bash scripts/check_screenshots.sh` | 240 total PNGs maintained |
| SCREEN-MAP variant count accurate | `docs/screens/SCREEN-MAP.md:30` currently says `(6)` for `chat_*` — add new row if variant count changes | Count matches `ls docs/screens/06-chat/designs/chat_thread_*` |
| No accessibility regression | Dark-mode contrast check on reference tokens | All message text ≥ 4.5:1, chips ≥ 3:1 against surface |

### 3.3 `architect` — Architecture Impact
- **No production architecture change.** All touches are in `docs/` + possibly `test/screenshots/drivers/goldens/` (CI auto-commits goldens anyway).
- **Design-system invariant preserved** — reference HTML MUST mirror the dark-mode MD3 tokens already used in `chat_thread_mobile_dark_scam_alert/code.html` (authoritative source).
- **No new dependencies.** HTML is self-contained; PNG is derived from rendering + screenshotting that HTML at 1290×2796 (iOS 6.7") — matches existing design PNG conventions.
- **Review gate stays the same** — PR still requires belengaz or reso approval per sprint plan §Conflict Prevention.

---

## 4 · Deliverables (ordered by dependency)

### 4.1 Design Reference (primary)
| File | Action | Source |
|:-----|:-------|:-------|
| `docs/screens/06-chat/designs/chat_thread_mobile_dark/code.html` | **Create** | Derive from `chat_thread_mobile_dark_scam_alert/code.html` (already dark-palette correct) **minus** the scam-alert `<div class="bg-error-container ..."` banner (§176-189 of that file). Visually equivalent to the light variant at [`chat_thread_mobile_light/code.html`](docs/screens/06-chat/designs/chat_thread_mobile_light/code.html) but with dark tokens. |
| `docs/screens/06-chat/designs/chat_thread_mobile_dark/screen.png` | **Create** | Rendered PNG of the above HTML at **1290×2796 logical** (iOS 6.7") — matches the dimension convention of existing dark-mode PNG references. If the user has already attached a designer handoff PNG (1290×2796), use that as-is instead of rendering. |

### 4.2 Sprint Plan + Screen Map Updates
| File | Change |
|:-----|:-------|
| `docs/SPRINT-PLAN.md:287-288` | Flip `[ ] P-43 …🔄 PR #161 open` → `[x] P-43 … ✅ PR #161` and remove the `⏳ Blocked on designer handoff` sub-bullet (replace with `✅ Dark-mode chat thread design added — issue #164`) |
| `docs/screens/SCREEN-MAP.md:30` | Confirm variant count for `chat_*` (was "(6)") — after addition will become "(7)" if we count the new normal-dark folder separately, or stay "(6)" if we count folders (3 chat_* + 4 messages_* + 4 scam_*). Read current formula and update only if drift. |

### 4.3 Golden Baseline (secondary — auto-handled by CI)
The existing `screenshots.yml` workflow auto-commits regenerated goldens on PR push via the `github-actions[bot]` step introduced in PR #161 commit `bbd71fe`. We do **not** regenerate locally (Windows vs macOS font drift would produce flaky baselines — same root cause as the H-1 CI fix on PR #161).

### 4.4 Issue & PR Close-Out
| Action | Target |
|:-------|:-------|
| Close issue #164 with resolution comment referencing commit SHA + new design PNG path | issue #164 |
| Update `docs/PLAN-p43-aso.md` § retrospective (if it has a follow-ups section) | — |
| Open PR against `dev` with full test plan + screenshots | new PR |

---

## 5 · Implementation Steps (verifiable — per plan.md Output Template)

| # | Task | File(s) | Verify |
|:--|:-----|:--------|:-------|
| 1 | Copy & adapt `chat_thread_mobile_dark_scam_alert/code.html` — remove scam-alert banner block; keep header / listing card / messages / offer card / input bar identical | `docs/screens/06-chat/designs/chat_thread_mobile_dark/code.html` | `diff` shows only removed `<div>` for scam banner; palette tokens unchanged; opens in browser without layout shift |
| 2 | Validate HTML tokens match dark theme — check that the `tailwind.config` colours align with existing dark reference (note: scam_alert HTML has a `"background": "#121212"` / `"on-surface": "#f2f2f2"` dark override — preserve these) | same file | `grep '"background"\|"on-surface"' ...` → `#121212` / `#f2f2f2` |
| 3 | Generate `screen.png` at 1290×2796 — either use attached designer PNG (if the image user sent is the dark reference) **or** render HTML via headless Chrome / screenshot tool at that resolution, strip EXIF | `docs/screens/06-chat/designs/chat_thread_mobile_dark/screen.png` | `identify screen.png` → `1290x2796`; file size < 2 MB; no EXIF |
| 4 | Update [`docs/SPRINT-PLAN.md:287-288`](docs/SPRINT-PLAN.md:287) — mark P-43 done, remove designer-handoff blocker bullet | `docs/SPRINT-PLAN.md` | Only two lines changed; `dart run scripts/check_quality.dart` green |
| 5 | Check `docs/screens/SCREEN-MAP.md` variant count drift for chat_* row | `docs/screens/SCREEN-MAP.md` | Count matches `ls docs/screens/06-chat/designs/chat_thread_*` |
| 6 | Run local quality gates | — | `dart run scripts/check_quality.dart` ✓ · `bash scripts/check_screenshots.sh` ✓ · `flutter analyze --no-pub` ✓ (nothing to analyze in `lib/`) |
| 7 | Commit with `docs(chat): add dark mode chat thread design reference (closes #164)` | — | Pre-commit hooks green (format, analyze, quality, coverage — last is N/A, no `lib/` diff) |
| 8 | Push; CI runs `screenshots.yml` → auto-commits any baseline drift on the branch | — | 8/8 CI checks green on PR |
| 9 | Open PR `feature/pizmam-P43-dark-mode-chat-golden` → `dev` using `/pr` workflow; request review from belengaz or reso | — | PR created with full test plan referencing issue #164 |
| 10 | After merge: close issue #164 with resolution comment pointing to the PR + design PNG | — | Issue #164 state = CLOSED |

---

## 6 · Risks & Mitigations

| # | Risk | Likelihood | Impact | Mitigation |
|:-:|:-----|:----------|:-------|:-----------|
| R1 | The image the user just attached is **not** the designer handoff (could be a test golden, a reference from the app, or unrelated) | Medium | Low | Plan step 3 has a fork: use attached PNG IF confirmed by user, else render from the derived HTML (no blocker) |
| R2 | Rendered HTML PNG differs visually from the actual Flutter golden (font hinting, anti-aliasing) | Low | Low | This is expected — the design PNG is a **reference for reviewers**, not a pixel-exact source of truth for the golden. The golden stays deterministic via the Flutter test driver. |
| R3 | CI auto-commits a baseline drift that conflicts with an in-flight parallel PR (e.g. PR #168 a11y follow-up) | Low | Medium | Chat-thread goldens are not touched by PR #168 (which is a11y-focused on other screens); rebase strategy if conflict appears. |
| R4 | SCREEN-MAP.md count mis-match triggers `check_quality` regression | Very Low | Low | Step 5 explicitly audits; fix inline before commit. |
| R5 | HTML reference renders incorrectly in non-Chromium browsers used by reviewers (Safari, Firefox) | Low | Very Low | Use the **exact** CDN + Tailwind config that the existing light/dark references use — proven to render consistently. |
| R6 | Dark-mode HTML tokens drift from actual `DeelmarktColors.dark*` values | Low | Medium | The scam_alert HTML already uses `#121212`/`#f2f2f2` — matches `DeelmarktColors.darkScaffold` / `DeelmarktColors.darkOnSurface` (verified [colors.dart:59-65](lib/core/design_system/colors.dart:59)). Re-use those values 1:1. |

---

## 7 · Pre-Implementation Verification (CLAUDE.md §7.1 mandatory)

### Schema (N/A)
No Supabase queries, no Edge Function, no migration.

### Sibling conventions (design reference folder)
- All sibling variants under `docs/screens/06-chat/designs/` follow `<variant_name>/{code.html,screen.png}` convention ✓
- HTML uses Tailwind CDN + Google Fonts + Material Symbols; dark variants add `class="dark"` to `<html>` ✓
- PNG dimensions: mobile variants are 1290×2796 (iOS 6.7") or 375×812 depending on iPhone variant — will match the existing `chat_thread_mobile_dark_scam_alert/screen.png` dimension precisely.

### Epic acceptance criteria audit (E04 Messaging + issue #164)
| Criterion | Coverage |
|:----------|:--------:|
| `chat_thread_mobile_dark.png` delivered under `docs/screens/06-chat/designs/` | Fully (step 3) |
| Golden regenerated via `flutter test --update-goldens …/chat_thread_screenshot_test.dart` | Fully (step 8 — CI auto-commit path) |
| `docs/screens/SCREEN-MAP.md` variant count updated if new design adds a variant | Fully (step 5) |

### Existing UI/logic scan
- `ChatThreadScreen` widget [chat_thread_screenshot_test.dart:27](test/screenshots/drivers/chat_thread_screenshot_test.dart:27) → no change needed; widget already renders dark mode correctly.
- Spec [`docs/screens/06-chat/02-chat-thread.md:16`](docs/screens/06-chat/02-chat-thread.md:16) → "Dark mode: Required" — confirmed.
- `DeelmarktTheme.dark` → no change needed; P-47 (PR #157) already shipped dark mode.
- Goldens under `test/screenshots/drivers/goldens/chat_thread_*_dark_*.png` (24 files) → stay as authoritative implementation snapshot.

### Design reference (CLAUDE.md §7.1 UI-task format)
- **Spec:** [`docs/screens/06-chat/02-chat-thread.md`](docs/screens/06-chat/02-chat-thread.md) ✓ (layout §1–6, l10n §78–92, dark-mode requirement line 16)
- **Designs checked:**
  - `chat_thread_mobile_light/screen.png` ✓ (layout source of truth — seen; Dutch copy, Canyon Speedmax €149, offer card)
  - `chat_thread_mobile_dark_scam_alert/screen.png` ✓ (dark palette source of truth — seen; same layout + red scam banner)
  - `chat_thread_desktop_expanded/` ✓ (sanity check for responsive parity)
- **All l10n keys from spec present in both locale files** — confirmed via PR #161 merged state (check_aso / check_quality both green on merge).

---

## 8 · Agent Assignments (single-domain)
| Task | Role | Domain |
|:-----|:-----|:-------|
| Design reference creation + docs updates | pizmam (self, Frontend/Design) | `docs/screens/` |
| PR open + CI gate shepherding | pizmam | `/pr` workflow |
| Review approval | belengaz OR reso | per sprint plan §Conflict Prevention |

---

## 9 · Completion Criteria

- [ ] `docs/screens/06-chat/designs/chat_thread_mobile_dark/code.html` exists and renders cleanly in Chromium
- [ ] `docs/screens/06-chat/designs/chat_thread_mobile_dark/screen.png` exists at 1290×2796, no EXIF, <2MB
- [ ] `docs/SPRINT-PLAN.md` — P-43 marked done, designer-handoff blocker removed
- [ ] `docs/screens/SCREEN-MAP.md` — variant count accurate
- [ ] Local gates green: `check_quality.dart`, `check_screenshots.sh`, `flutter analyze`
- [ ] PR opened to `dev` with complete test plan and design PNG attached
- [ ] All 8 CI checks pass (Format & Analyze, CodeQL, ASO Copy Lint, Screenshot Audit, Regenerate & Diff Screenshots, Analyze JS/TS, Test & Coverage, Security Scan)
- [ ] Reviewer approval from belengaz or reso
- [ ] PR merged to `dev`
- [ ] Issue #164 closed with resolution comment referencing merged commit

---

## 10 · Next Workflow Steps

After user approval:
1. `/implement` or direct execution of §5 steps 1→10
2. Post-implementation: `/plan-complete` hook logs retrospective to `.agent/contexts/plan-quality-log.md`
3. Sprint plan update triggers no additional cascading tasks — P-43 closes fully.

---

_Generated via `.agent/workflows/plan.md` v2.2.0_
_Validated against: CLAUDE.md §7.1, §8, §10, §13 · `.agent/workflows/quality-gate.md` (rejection triggers: none fired) · Specialist Synthesis Protocol (security-reviewer, tdd-guide, architect)_
