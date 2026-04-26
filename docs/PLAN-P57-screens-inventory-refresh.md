# PLAN-P57 — Refresh `docs/SCREENS-INVENTORY.md` + add anti-staling controls

> **Owner:** 🔵 pizmam (`@emredursun`)
> **Branch:** `feature/pizmam-audit-quickwins-P56-P57-P58` (shared)
> **Severity / Audit ref:** P2 / `M3` (preflight) · `P-57` (retrospective)
> **Effort:** S — ≤ 1 day
> **Workflow:** `/plan` v2.2.0 + `/quality-gate` v2.1.0 principles
> **Task size:** Trivial-to-Medium (1 doc file + optional 1 enforcement script)
> **Created:** 2026-04-25 · Status: ⏳ Awaiting approval

---

## 1. Context (the "why")

`docs/SCREENS-INVENTORY.md` was last touched **2026-03-26** (~30 days stale per the audit). Its summary still reports:

> Implemented: 5 · Placeholder: 9 · Not started: 16

This is severely out-of-date. Per `docs/SPRINT-PLAN.md`, **all 30 screens** plus the 14 shared widgets are now checked off (`P-14..P-53` = ✅, `B-29..B-33` = ✅). Sprint 9–10 alone shipped chat (P-35/36), reviews (P-38), seller profile (P-39), admin panel Phase A (P-40), seller-mode home (P-41), accessibility audit (P-42), ASO (P-43), social login (P-44), web/PWA (P-45..P-52), and suspension/appeal (P-53).

A status doc that still says "Not started" 30 days after shipping is a **process risk**:
- onboarding new contributors mis-routes work to "build the registration screen" when it exists
- ASO marketing copy / claims_ledger may reference "coming soon" features that already shipped
- audit/ALL-04 (seed 500+ listings) blocked on screens that the doc claims don't exist

CLAUDE.md §11 ("Session Workflow → Before Ending") implicitly requires inventories stay current, but enforces nothing. The audit elevates this to a Tier-1 hygiene gap.

---

## 2. Decisions Required (Socratic gate, pre-answered)

| # | Question | Decision | Rationale |
|---|----------|----------|-----------|
| **D1** | One-shot refresh, or one-shot + automation guard? | **Both.** This PR ships a refresh **and** a `scripts/check_screens_inventory.dart` lightweight check. | Without an enforcement seam, the doc will drift again in 30 days. CLAUDE.md §8 culture is "rules → automated checks". |
| **D2** | Add new status values? | **Yes — extend to:** `Implemented` · `Implemented (placeholder content)` · `In Progress` · `Blocked` · `Not started` | Today's binary `Implemented / Placeholder / Not started` cannot represent "screen exists, real Supabase wiring done, but uses placeholder copy" (e.g. legal copy pending) — common reality on this project. |
| **D3** | Add responsive-variant matrix per screen (compact / medium / expanded × light / dark)? | **Yes — minimal table per screen** (✅/⚠️/❌ for each 3×2 grid cell). | Audit found 11 over-budget screens already need responsive review. Inventory becomes the index. |
| **D4** | Cross-link to design tokens / patterns / screenshots? | **Yes — three relative links per screen row** when present: spec md, design png, golden test. Skip when absent. | Today the doc points only at `docs/screens/` — but the design tokens, patterns, and golden assets are scattered. Inventory is the obvious concierge. |
| **D5** | Auto-generate the inventory from a script? | **Out of scope (P-57a follow-up).** | Auto-generation requires a stable mapping from route → screen-file → spec md. Not all routes have specs yet. Manual refresh now; automate later. Tracked. |
| **D6** | Update the "Implementation Status" summary numbers? | **Yes — recompute from SPRINT-PLAN.md and current `lib/features/**/presentation/screens/` contents.** | The summary is the headline; if it's wrong, nothing else matters. |
| **D7** | Should new statuses imply CI behaviour? | **No — informational only for v1.** | Tying statuses to CI gates risks overreach. Phase 2 only. |
| **D8** | Touch existing inline "Design notes" sections? | **No — preserve verbatim** unless they reference shipped functionality as "coming soon". | Design notes are spec-grade content and out of pizmam-only scope to alter. |
| **D9** | Include shared-widgets table refresh? | **Yes — same diligence**: status updates from SPRINT-PLAN.md (P-19/20/22/30/31/32/34 are all done now). | Inventory is a single document; partial refresh is anti-pattern. |

---

## 3. Scope

### In-scope (this PR closes)
- ✏️ Update `docs/SCREENS-INVENTORY.md` summary table (current counts)
- ✏️ Update each of 30 screen rows: status, ASO/legal-copy notes if relevant
- ✏️ Update each of 14 shared-widget rows
- ➕ Add per-screen responsive-variant matrix (compact / medium / expanded × light / dark)
- ➕ Add per-screen cross-link block (spec md · design png · golden test) when present
- ➕ New section "Status Vocabulary" documenting D2's enum values
- ➕ New section "Last reviewed" date footer with reviewer handles
- ➕ Update header "Last updated: 2026-04-25" + add "Maintainer: pizmam (@emredursun)"
- 🆕 New `scripts/check_screens_inventory.dart` — fails CI if `Last updated:` is older than 60 days
- 🧪 New `test/scripts/check_screens_inventory_test.dart`
- 📄 Update `docs/CHANGELOG.md` Unreleased section

### Out-of-scope (do **not** touch)
- ❌ Auto-generation script (P-57a — follow-up)
- ❌ Fixing the design notes themselves (out of pizmam-only ownership scope)
- ❌ Adding routes that don't exist (router changes are belengaz scope)
- ❌ New screens — this is a *bookkeeping* refresh only
- ❌ `docs/screens/` sub-directory (separate concern)

---

## 4. Mandatory Rule Consultation

| Rule | Applicable? | How addressed |
|------|-------------|---------------|
| §1 Architecture | No (doc-only) | — |
| §2.1 File length | **Yes** — current file is 244 lines; refresh will grow. | Split if >800 lines (CLAUDE.md absolute max). Estimated post-refresh: ~400 lines. OK. |
| §2.2 Naming | Yes (CLAUDE.md kebab/snake conventions) | Status enum values use natural English, not snake_case (it's prose) |
| §3.3 No duplication | **Yes** | Do not duplicate facts that live in SPRINT-PLAN.md; cross-link instead |
| §4.1 Design system | Yes (mandatory references) | New responsive matrix references `docs/design-system/tokens.md` breakpoints |
| §6.2 Test structure | Yes | New `check_screens_inventory.dart` script gets its own test |
| §7 Pre-implementation checklist | Yes (UI tasks) | Inventory IS the screen-spec index → §7.5 satisfied |
| §8 Quality Gates | Yes | New script becomes a quality gate (D1 decision) |

### `/quality-gate` Ethics & Safety Pass

| Domain | Result |
|--------|--------|
| AI Bias | N/A — no automated decision |
| Privacy / GDPR | N/A — no PII; document references `auth.users` rows by feature, not by data |
| Automation Safety | ⚠️ The 60-day staling check could spam CI if the team is on holiday. Mitigation: warn, do not fail, in first iteration; promote to fail after 14 days of warning. |
| User Autonomy | N/A |
| Human-in-the-Loop | ✅ All updates manually authored; no LLM-generated rows |

**Ethics verdict: ✅ APPROVED.** No rejection trigger fires.

---

## 5. Implementation Tasks (with verification criteria)

| # | Task | File(s) | Verification |
|---|------|---------|--------------|
| 1 | Audit current state: cross-reference SPRINT-PLAN.md tasks against inventory rows | (read-only) | Tabular diff in PR body |
| 2 | Update Summary block | `docs/SCREENS-INVENTORY.md` lines 9–17 | Implemented count = 30 (or actual at audit time); Placeholder/Not started → 0 unless real |
| 3 | Add "Status Vocabulary" section after Summary | `docs/SCREENS-INVENTORY.md` | New `## Status Vocabulary` heading with 5 enum values + plain-English definitions |
| 4 | Refresh Auth/Onboarding rows (5 screens) | section §1 | Status column reflects PR/issue evidence; design notes preserved |
| 5 | Refresh Home/Browse rows (4 screens) | section §2 | Same |
| 6 | Refresh Listings rows (3 screens) | section §3 | Same |
| 7 | Refresh Payments/Transaction rows (3 screens) | section §4 | Same |
| 8 | Refresh Shipping rows (3 screens) | section §5 | Same |
| 9 | Refresh Chat/Messages rows (3 screens) | section §6 | Same |
| 10 | Refresh Profile/Settings rows (4 screens) | section §7 | Same |
| 11 | Refresh Admin/Moderation rows (1 screen) | section §8 | Same |
| 12 | Refresh Shared Widgets rows (14 widgets) | section "Shared Widgets" | All P-19/20/22/30/31/32/34 now `Implemented` per SPRINT-PLAN.md |
| 13 | Add responsive-variant matrix appendix | new appendix `## A. Responsive Variant Matrix` | 30×6 cells; each ✅/⚠️/❌ |
| 14 | Add cross-link appendix | new appendix `## B. Cross-Link Index` | Per-screen: spec.md / design.png / golden test paths |
| 15 | Update header dates + maintainer | line 4 + new footer | "Last updated: 2026-04-25" + "Maintainer: pizmam (@emredursun)" + "Next review: 2026-06-24" |
| 16 | Create `scripts/check_screens_inventory.dart` | new file | Reads header date; warns if >60d old, fails if >120d |
| 17 | Wire script into pre-push hook | `.husky/` or equivalent | Hook runs script; documented in CLAUDE.md §8 |
| 18 | Create script unit test | `test/scripts/check_screens_inventory_test.dart` | 3 cases: fresh / warn / fail |
| 19 | Update CHANGELOG | `docs/CHANGELOG.md` | New row under Unreleased |

**Estimated total:** 4–6 hours including hook integration + test writing.

---

## 6. Cross-cutting Concerns

### Security / Privacy
- No PII; no secrets; no GDPR scope

### Testing
- New script gets its own test (CLAUDE.md §6.2 — every utility ≤100 lines testable)
- Test cases:
  1. Fresh document (≤60d) → exit 0
  2. Warning band (61–119d) → exit 0 with stderr warning
  3. Stale (≥120d) → exit 1

### Documentation
- The inventory **is** documentation; this PR is meta-doc maintenance
- New "Status Vocabulary" + "Cross-Link Index" sections become referenced from `docs/screens/` README

### Accessibility
- No UI; no a11y impact

### Localisation
- The doc itself stays English (matches existing convention); no l10n keys

### Performance
- Doc growth ~250 lines → ~400 lines; well below §2.1 800-line ceiling

### Observability
- The new staling check is itself the observability primitive

---

## 7. Risk Matrix

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|-----------|--------|-----------|
| **R1** | Cross-referencing SPRINT-PLAN.md against actual `lib/features/**` reveals more drift than expected (e.g. screen file exists but route is missing) | Medium | Medium | Document the drift in PR body; do not silently "fix" misses — flag to belengaz (router scope). |
| **R2** | Responsive matrix gathering time-consuming (30×6 = 180 cells) | Medium | Low | Batch by inspection of `lib/widgets/responsive/` and existing goldens; ✅ default if golden exists, ⚠️ if visual-only review pending, ❌ if not yet implemented. |
| **R3** | The 60-day script becomes alert fatigue noise | Low | Medium | Two-band approach (warn → fail) gives the team a buffer; warning text includes "remediation: bump `Last updated:` after refresh". |
| **R4** | Scope creep — temptation to also fix design notes | Medium | Medium | D8 explicitly excludes; reviewer enforcement. |
| **R5** | New script breaks because of CLAUDE.md frontmatter format change | Low | Low | Script reads `Last updated:` line via simple regex; document the contract in script docstring. |
| **R6** | Inventory contradicts ALL-LAUNCH decomposition (Weeks 21–22) | Low | High | Cross-link to `docs/launch/CHECKLIST.md` (when belengaz creates it per ALL-LAUNCH); flag mismatch in PR description. |

---

## 8. Rollback Plan

- **Doc revert:** single-commit `git revert` restores prior text. Inventory data is not authoritative for any system; downstream consumers (humans) tolerate the revert without action.
- **Script revert:** removing `scripts/check_screens_inventory.dart` and the hook line is single-commit. CI does not depend on it as a blocking gate in v1 (warning-only mode).

**Rollback eligibility:** unconditional.

---

## 9. Quality Gate Checklist (pre-merge)

| Gate | Owner | Evidence |
|------|-------|---------|
| All status changes traceable to a SPRINT-PLAN.md row or PR# | pizmam | PR body cross-reference table |
| Responsive matrix consistent with `test/screenshots/drivers/goldens/` | pizmam | Matrix vs `ls test/screenshots/drivers/goldens/*.png` |
| `flutter analyze --fatal-infos` clean (script is Dart) | pizmam | CI |
| `dart run scripts/check_quality.dart --all` zero violations | pizmam | CI |
| New script test passes | pizmam | `dart test test/scripts/check_screens_inventory_test.dart` |
| Doc renders correctly on GitHub | pizmam | Self-review of PR file diff |
| Reviewer approval | belengaz or reso | GitHub PR |

---

## 10. Acceptance Criteria (for PR description)

- [ ] `docs/SCREENS-INVENTORY.md` Summary block reflects 2026-04-25 reality
- [ ] All 30 screen rows reviewed; status updated where evidence exists
- [ ] All 14 shared widgets reviewed; status updated
- [ ] New `## Status Vocabulary` section present
- [ ] New `## A. Responsive Variant Matrix` appendix present
- [ ] New `## B. Cross-Link Index` appendix present
- [ ] Header `Last updated:` advanced; `Maintainer:` added; `Next review:` added
- [ ] `scripts/check_screens_inventory.dart` created (≤100 lines)
- [ ] `test/scripts/check_screens_inventory_test.dart` 3 cases passing
- [ ] Pre-push hook invokes the script (warn-only band documented)
- [ ] `docs/CHANGELOG.md` Unreleased section updated
- [ ] CI green
- [ ] Closes preflight finding `M3`; closes retrospective task `P-57`

---

## 11. Sequencing Note

Land **after** P-58 (avoid mixing dependency change with doc churn in bisects) and **before** P-56 (P-56 modifies `lib/core/services/` — keeping doc PR ahead of code PR is reviewer-friendly).

---

## 12. Provenance

- **Workflow:** `.agent/workflows/plan.md` v2.2.0 (Trivial-Medium track) + `/quality-gate` v2.1.0 ethics check (APPROVED)
- **Audit cross-references:** `docs/audits/2026-04-25-tier1-retrospective.md#p-57`, `docs/audits/2026-04-25-tier1-preflight.md#m3`
- **Rule bases:** CLAUDE.md §2.1 / §8 / §11; design system tokens
- **No specialist synthesis required** (Trivial-Medium; no architecture, security, or test-strategy decisions beyond standard tooling)
