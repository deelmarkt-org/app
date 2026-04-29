# Tier-1 Retrospective Audit — Pre-Launch

> **Date:** 2026-04-25 · **Sprint:** 9–10 → Integration + Launch
> **Workflow:** `/retrospective` (`.agent/workflows/retrospective.md` v2.1.0)
> **Auditor:** Senior Staff Engineer (Claude Opus 4.7, 1M context) under owner authorization
> **Bar:** Google / Meta / Apple / Stripe production standards
> **Scope:** 521 Dart files · 489 test files · 22 Edge Functions · 6 CI workflows · 50 migrations · 7 ADRs

---

## How to use this document

1. Each finding has an **owner tag**: 🔴 `[R-*]` reso (backend) · 🟢 `[B-*]` belengaz (full-stack/devops) · 🔵 `[P-*]` pizmam (frontend) · ⚫ `[ALL]` cross-team.
2. Task IDs continue from `SPRINT-PLAN.md` (R‑38, B‑55, P‑53 were the last) — you can copy these straight into the next sprint.
3. **Self-assign:** open the matching GitHub Issue (or create one with the suggested title), check the "Acceptance" block, link the PR.
4. Findings are ordered by **severity (P0 → P3)**, not by owner — see the *Self-Assignment Index* at the bottom for an owner-first view.

> ⚠️ **Verdict:** Strong engineering foundation, **not Tier-1 launch-ready**. Closing the **P0** bucket below is a blocking precondition for any production deploy. Estimated calendar: 2–3 weeks of focused work before ALL-05 store submission is responsibly attempted.

---

## TL;DR — 1-paragraph executive summary

DeelMarkt's codebase quality bar is genuinely high (Clean Architecture, Riverpod 3, 23/23 RLS, HMAC webhooks, ADRs, design tokens, 94% test-to-source ratio). However, **launch readiness is a different bar than code quality**. Three categories of risk currently make a public soft-launch premature: (1) **13+ Edge Functions on the money/PII path ship without automated tests**, (2) **operational safety nets are silently disabled** (OWASP ZAP skipped because `STAGING_URL` is unset; admin `is_admin()` is a client-side stub; rate limiting fails open), and (3) **Sprint 9–10 was reported "95% complete" with two security-critical tasks open and the entire launch sprint at 0%**. None of these are unfixable — they are all calendar-and-discipline issues, not capability issues.

---

## Compliance Classification (8 domains)

| # | Domain                       | Verdict                  | Anchor Evidence                                                    |
| - | ---------------------------- | ------------------------ | ------------------------------------------------------------------ |
| 1 | Task Delivery                | ⚠️ Partially Compliant   | B‑34/B‑35 unchecked; ALL‑01..06 = 0%                               |
| 2 | Code Quality                 | ⚠️ Partially Compliant   | 11 files exceed §2.1 limits; `intl: any`                           |
| 3 | Testing                      | ❌ **Non-Compliant**     | 13+ Edge Functions untested; only 2 integration tests              |
| 4 | Security                     | ⚠️ Partially Compliant   | ZAP silently skipped; rate-limit fails open; admin guard stub      |
| 5 | Performance                  | ⚠️ Partially Compliant   | No regression CI; fat APK; no Firebase Perf traces                 |
| 6 | Documentation                | ⚠️ Partially Compliant   | SCREENS-INVENTORY stale; ADR-022 reviewers pending; no runbooks    |
| 7 | Process                      | ⚠️ Partially Compliant   | Sprint declared 95% with security tasks open; no launch tracking   |
| 8 | Ethics / Privacy / a11y      | ⚠️ Partially Compliant   | DSA Art.17 transparency gap; R-37 emails undelivered; #148 avatars |

---

## P0 — Launch Blockers

> Must be closed before *any* production deploy. ETA target: this week → next week.

### 🔴 [R-39] Deno test coverage for GDPR Edge Functions
- **Owner:** `reso` · **Severity:** Critical · **Effort:** L (1–2 weeks)
- **Why:** `delete-account` (163 LOC), `export-user-data` (229 LOC), `gdpr-cleanup-auth` (111 LOC) ship to production with **zero automated tests**. GDPR Art. 17 / 20 paths require deletable-and-exportable guarantees that are currently only manually validated. A regression here is a regulator-level incident, not a bug.
- **Files:** `supabase/functions/delete-account/`, `supabase/functions/export-user-data/`, `supabase/functions/gdpr-cleanup-auth/`
- **Acceptance:**
  - [ ] `index_test.ts` next to each `index.ts` covering: happy path, RLS-failure, invalid-token, partial-data, audit-log written
  - [ ] Coverage ≥80% on these three functions (Deno coverage)
  - [ ] CI step: `deno test supabase/functions/{delete-account,export-user-data,gdpr-cleanup-auth}/**/*_test.ts` blocks merge

### 🟢 [B-56] Deno test coverage for Money-Path Edge Functions
- **Owner:** `belengaz` · **Severity:** Critical · **Effort:** L (1–2 weeks)
- **Why:** `create-payment` (245), `mollie-webhook` (348), `release-escrow` (367), `create-shipping-label` (479), `tracking-webhook` (224), `daily-reconciliation` (330), `webhook-dlq` (219) — every one of these manipulates ledger or third-party calls with no automated regression net. At Stripe these would be blocked from deploy without ≥90% line coverage.
- **Files:** `supabase/functions/create-payment/`, `supabase/functions/mollie-webhook/`, `supabase/functions/release-escrow/`, `supabase/functions/create-shipping-label/`, `supabase/functions/tracking-webhook/`, `supabase/functions/daily-reconciliation/`, `supabase/functions/webhook-dlq/`
- **Acceptance:**
  - [ ] `index_test.ts` per function with happy + 2 failure modes minimum
  - [ ] **Mollie webhook**: replay test (NX idempotency) + bad-signature test + Redis-down test
  - [ ] **release-escrow**: invalid-state-transition test + idempotency test
  - [ ] **create-shipping-label**: PostNL outage retry test + DHL fallback test
  - [ ] CI gate: `deno test supabase/functions/**/*_test.ts` passes; ≥80% coverage

### 🔴 [R-40] Replace admin `is_admin()` client-side stub with SECURITY DEFINER RPC
- **Owner:** `reso` · **Severity:** Critical · **Effort:** M (2–5 days)
- **Why:** `lib/features/admin/data/supabase/supabase_admin_repository.dart` carries `TODO(Phase 1.12 — reso): Replace with public.is_admin() SECURITY DEFINER`. Any production build with admin routes reachable + this stub = **privilege-escalation vector**. Also called out in ADR-002.
- **Acceptance:**
  - [ ] `public.is_admin(uuid)` SECURITY DEFINER function in a new migration with RLS-aware role check; declared with `SET search_path = ''` and a fully-qualified body (e.g. `public.user_roles`) so a hijacked search_path can't shadow it (CLAUDE.md §9 + Supabase advisory)
  - [ ] All admin RPC calls (`get_admin_stats`, `get_admin_activity`, etc.) gated by `public.is_admin(auth.uid())`
  - [ ] `supabase_admin_repository.dart` calls these RPCs (no client-side filtering)
  - [ ] **Until merged:** admin panel feature-flagged off in production builds via Unleash `admin_panel_phase_b`
  - [ ] Penetration test: forge a non-admin JWT and confirm 403/empty result for every admin endpoint

### 🟢 [B-57] OWASP ZAP scan: configure `STAGING_URL` + fail-loud on missing
- **Owner:** `belengaz` · **Severity:** Critical · **Effort:** S (≤1 day)
- **Why:** `.github/workflows/security-audit.yml` runs ZAP only `if STAGING_URL` is set. The variable is currently unset → the job skips silently every week → the team sees a green badge with zero web-app DAST coverage. **A silently-skipped security gate is worse than an absent one.** Closes B-34.
- **Acceptance:**
  - [ ] `STAGING_URL` configured in GitHub repo variables (e.g. `https://staging.deelmarkt.com`)
  - [ ] DNS alias for staging deploy verified
  - [ ] Workflow modified: if expected to run and `STAGING_URL` is empty → `exit 1` (do **not** skip silently)
  - [ ] Baseline ZAP scan run; findings triaged into a tracking issue
  - [ ] Slack alert wired on ZAP HIGH/CRITICAL findings

### 🟢 [B-58] Switch `create-payment` rate limiter from fail-open to fail-closed
- **Owner:** `belengaz` · **Severity:** High · **Effort:** S (≤1 day)
- **Why:** `supabase/functions/create-payment/index.ts` lines 114–155 — when Redis is unavailable, rate limiting is **skipped** (fails open). For a payment endpoint this is unacceptable at Tier-1; Stripe/Adyen return 503 on rate-limit infra failure.
- **Acceptance:**
  - [ ] On Redis error → return 503 Service Unavailable with `Retry-After: 30`
  - [ ] PagerDuty SEV-2 alert on rate-limit infra failure (so we hear about it instead of silently degrading)
  - [ ] ADR (or addendum to ADR-023) documenting the fail-closed decision and threat model
  - [ ] Mollie-webhook also reviewed for the same pattern

### 🔴 [R-41] Wire R-37 sanction email delivery (Resend or Supabase SMTP)
- **Owner:** `reso` · **Severity:** High · **Effort:** S (≤1 day)
- **Why:** Per SPRINT-PLAN.md R-37 note: *"Email delivery via Supabase SMTP / Resend will be tracked as a separate task once the email provider is configured."* Suspending a user without notice violates procedural-fairness expectations under DSA + ACM and breaks the 14-day appeal window since notice is the start of the clock.
- **Acceptance:**
  - [ ] Email provider chosen (Resend recommended) and API key in Supabase Vault
  - [ ] `send-sanction-notification/index.ts` actually delivers (template includes appeal deadline, reason, link)
  - [ ] **Suspension issuance gated** on email-sent confirmation (no silent suspensions)
  - [ ] NL + EN templates with l10n keys

### ⚫ [ALL-PROC-1] Re-open Sprint 9–10; do not close until B-34/B-35 tick
- **Owner:** all leads · **Severity:** High · **Effort:** S (process)
- **Why:** Calling a sprint 95% complete with two open security tasks is exactly how launch-week fires start. Definition-of-Done must include security gates green.
- **Acceptance:**
  - [ ] B-34 (ZAP) and B-35 (monitoring audit) explicitly checked or moved to Week 21 with named blocker
  - [ ] Sprint retrospective updated to reflect actual completion %

---

## P1 — Strongly Recommended Before Soft-Launch

### ⚫ [ALL-LAUNCH] Stand up Weeks 21–22 launch tracking
- **Owner:** all (split below) · **Severity:** High · **Effort:** L
- **Why:** ALL-01..ALL-06 currently have no sub-tasks, no day-level estimates, no acceptance criteria. At Apple/Stripe each would be a sub-page with named owner.
- **Acceptance:** create `docs/launch/CHECKLIST.md` with one row per item below, owner + ETA + acceptance:
  - [ ] **ALL-01** E2E rehearsal — register → list → buy → ship → confirm → release recorded as CI artifact (lead: `belengaz`)
  - [ ] **ALL-02** Pen-test remediation — close every ZAP HIGH/CRITICAL (lead: `belengaz`)
  - [ ] **ALL-03** Internal-test bug triage burn-down (lead: rotating)
  - [ ] **ALL-04** Seed 500+ listings via admin/import script (lead: `pizmam`+`reso`)
  - [ ] **ALL-05** App Store + Play Store metadata + privacy labels submitted (lead: `belengaz`+`pizmam`)
  - [ ] **ALL-06** Soft-launch invite-only Amsterdam — feature flag + capacity plan (lead: `belengaz`)

### 🔴 [R-42] Provision `avatars` Storage bucket + RLS (private, signed URLs)
- **Owner:** `reso` · **Severity:** High · **Effort:** S
- **Why:** `lib/features/profile/data/services/supabase_avatar_upload_service.dart` carries `TODO(#148): avatars bucket + RLS must be provisioned by reso before [...] Decide public vs private bucket before provisioning.` Profile-photo upload is currently broken. Default should be **private with signed URLs** (GDPR Art. 5(1)(c) data minimisation; public bucket exposes faces to scraping/reverse-image search).
- **Acceptance:**
  - [ ] Migration creates `avatars` Storage bucket as **private**
  - [ ] RLS: insert/update/delete only on `auth.uid() = owner`
  - [ ] Signed URL helper in `lib/core/services/storage_service.dart`
  - [ ] Avatar upload flow validated end-to-end on staging
  - [ ] Issue #148 closed

### 🟢 [B-59] Add `scripts/check_edge_functions.sh --all` to CI
- **Owner:** `belengaz` · **Severity:** Medium · **Effort:** S
- **Why:** The script today runs only as a pre-commit hook on staged files. A developer using `--no-verify` (forbidden but not technically blocked at push) silently bypasses it. Promote to a CI gate.
- **Acceptance:**
  - [ ] New job in `ci.yml` running the script with `--all` flag
  - [ ] Job blocks merge on schema-mismatch / missing imports / pattern violations

### 🟢 [B-60] Replace heuristic license check with `pana` + emit SPDX SBOM
- **Owner:** `belengaz` · **Severity:** Medium · **Effort:** S
- **Why:** Today: `grep -qi "gpl\|agpl" pubspec.lock` (CI ci.yml lines 122–139). Misses transitive GPL via native deps and dual-licensed packages. SBOM is increasingly expected by Apple/Google review and is a SOC 2 / ISO 27001 prerequisite.
- **Acceptance:**
  - [ ] `pana` (or `licensee`) integrated in `security-audit.yml`
  - [ ] SPDX JSON SBOM produced as build artifact per release
  - [ ] CI fails on GPL/AGPL findings unless explicitly approved in a `LICENSES.allowlist`

### 🟢 [B-61] Codemagic (B-05) — unblock Apple Dev + Google Play accounts
- **Owner:** `belengaz` · **Severity:** High · **Effort:** M
- **Why:** Account procurement is on the critical path to ALL-05 store submission. Should have been a Sprint-1 long-lead item.
- **Acceptance:**
  - [ ] Apple Developer Program account active (organization, not personal)
  - [ ] Google Play Console account active
  - [ ] Codemagic configured for both pipelines (`codemagic.yaml` validated end-to-end)
  - [ ] First TestFlight + Play Internal build delivered

### ⚫ [ALL-E2E] Integration tests for the 5 critical user flows
- **Owner:** mixed (see below) · **Severity:** High · **Effort:** L
- **Why:** Today only `rate_limit_seam_test.dart` and `suspension_flow_integration_test.dart` exist. Listing creation, search, payment, chat, shipping have no integration coverage. Unit tests don't catch contract drift between layers.
- **Acceptance (split):**
  - [x] 🔵 [P-54] `e2e_listing_creation_test.dart` — capture → form → publish → appears in search ✅ 2026-04-29 — `test/integration/e2e_listing_creation_test.dart`
  - [ ] 🟢 [B-62] `e2e_payment_workflow_test.dart` — checkout → escrow → tracking → release
  - [ ] 🟢 [B-63] `e2e_shipping_test.dart` — label → tracking events → delivery confirmation
  - [ ] 🔴 [R-43] `e2e_chat_offer_test.dart` — message → offer → accept → transaction
  - [ ] All five run against staging Supabase in CI as a `nightly` job; <20 min total

---

## P2 — Quality Debt to Repay Before / Just After Launch

### 🔵 [P-54] Decompose 9 over-budget screens (CLAUDE.md §2.1)
- **Owner:** `pizmam` · **Severity:** Medium · **Effort:** M
- **Files (lines):**
  - `lib/features/messages/presentation/screens/chat_thread_screen.dart` (228)
  - `lib/features/home/presentation/screens/category_detail_screen.dart` (228)
  - `lib/features/listing_detail/presentation/widgets/detail_loading_view.dart` (225)
  - `lib/features/search/presentation/widgets/search_results_view.dart` (225)
  - `lib/features/transaction/presentation/screens/mollie_checkout_screen.dart` (248) ← **highest priority** (payment-critical)
  - `lib/features/home/presentation/widgets/home_data_view.dart` (209)
  - `lib/features/listing_detail/presentation/listing_detail_screen.dart` (205)
  - `lib/features/profile/presentation/screens/appeal_screen.dart` (205)
  - `lib/features/sell/presentation/screens/listing_creation_screen.dart` (204)
- **Acceptance:** each ≤200 lines per §2.1; tests still green; sub-widgets extracted into the same feature's `presentation/widgets/`.

### 🔵 [P-55] Decompose 3 admin widgets currently carrying TODO(#133)
- **Owner:** `pizmam` · **Severity:** Medium · **Effort:** S
- **Files:** `admin_activity_feed.dart` (217), `admin_empty_state.dart` (229), `admin_sidebar.dart` (221)
- **Acceptance:** each ≤200 lines; admin panel screenshot tests still match.

### 🟢 [B-64] Decompose 2 oversized Supabase repositories
- **Owner:** `belengaz` · **Severity:** Medium · **Effort:** S
- **Files:** `supabase_listing_repository.dart` (231), `supabase_message_repository.dart` (207)
- **Acceptance:** each ≤200 lines; split by operation group (recent/nearby/search/favourites for listings; fetch/send/subscribe for messages).

### 🟢 [B-65] Ship App Bundle (.aab) — replace fat APK in Play Store path
- **Owner:** `belengaz` · **Severity:** Medium · **Effort:** S
- **Why:** Current production path = ~62 MB fat APK. Should be ABI-split bundle (~22 MB per device).
- **Acceptance:** Codemagic produces `--release --split-debug-info` App Bundle; Play Store accepts it; on-device install size verified <30 MB.

### 🔵 [P-56] Add Firebase Performance custom traces
- **Owner:** `pizmam` (with `belengaz` for SLO config) · **Severity:** Medium · **Effort:** S
- **Why:** Firebase Performance SDK is included but has zero custom traces — pure overhead. Apple App Store review and Google Vitals weight startup time heavily.
- **Acceptance:** named traces for `app_start`, `listing_load`, `search_query`, `payment_create`, `image_load`; p95 SLO documented per trace.

### 🟢 [B-66] CPU/memory/startup regression CI
- **Owner:** `belengaz` · **Severity:** Medium · **Effort:** M
- **Acceptance:** new `performance.yml` workflow; baseline values checked in; PRs fail on >10% regression.

### 🟢 [B-67] Author repo-root `SECURITY.md` (disclosure policy + PGP)
- **Owner:** `belengaz` · **Severity:** Medium · **Effort:** S
- **Why:** Required by GitHub Security Advisories program; expected under EU NIS2 for in-scope services.

### 🟢 [B-68] Author runbooks for the 5 most likely incidents
- **Owner:** `belengaz` · **Severity:** Medium · **Effort:** M
- **Files to create under `docs/runbooks/`:** Mollie webhook failure · Redis outage · Supabase RLS regression · certificate-pinning rotation · App Store rejection.

### 🔵 [P-57] Refresh `docs/SCREENS-INVENTORY.md` (last updated 2026-03-26)
- **Owner:** `pizmam` · **Severity:** Low · **Effort:** S
- **Why:** Sprint 9–10 shipped multiple screens after the doc was last refreshed; status drift is a leading indicator of process drift.
- **Acceptance:** every screen marked correctly; "last updated" header advanced.

### ⚫ [ALL-ADR] ADR-022 review sign-off (belengaz + reso)
- **Owners:** `belengaz`, `reso` · **Severity:** Low · **Effort:** S
- **Why:** ADR-022 sits in "Accepted" with reviewers field still listed as pending; either move to "Proposed" or close out.

### 🔵 [P-58] Pin `intl` and platform-interface dependencies
- **Owner:** `pizmam` · **Severity:** Low · **Effort:** S
- **Why:** `pubspec.yaml` lines 17, 107, 108 — `intl: any`, `image_picker_platform_interface: any`, and `plugin_platform_interface: any` all defeat reproducible builds. A passing CI today can ship a different transitive set tomorrow purely from upstream publication timing.
- **Acceptance:** all three pinned to a `^x.y.z` constraint matching the current resolved version (`flutter pub deps --no-dev | grep -E 'intl|image_picker_platform_interface|plugin_platform_interface'`); locale + image-picker tests still green; `pubspec.lock` regenerated and committed.

---

## P3 — Strategic / Maturity (post-launch acceptable)

### 🔴 [R-44] DSA Art. 17 transparency for scam-detection
- **Owner:** `reso` (data) + `pizmam` (UI) · **Severity:** Medium (DSA risk) · **Effort:** M
- **Why:** Today an ML-flagged user gets no statement of reasons. Under DSA Art. 17 + the upcoming EU AI Act transparency obligations for risk-relevant automated decisions, this is a compliance gap, not just a UX gap.
- **Acceptance:**
  - [ ] `scam_flags` table records `(rule_id, score, version, model_version)` per flag
  - [ ] User-facing "why was this flagged?" copy with appeal link
  - [ ] Appeals route to moderation queue, not auto-resolved

### 🔴 [R-45] Bias evaluation + model card for scam-detection ML
- **Owner:** `reso` · **Severity:** Medium · **Effort:** M
- **Acceptance:** `docs/ml/scam-detection-model-card.md` with FP rate by region/category/seller-tier; bias metrics published; review cadence (quarterly) committed.

### 🟢 [B-69] Web LCP/CLS Lighthouse CI budget
- **Owner:** `belengaz` · **Severity:** Low · **Effort:** M
- **Acceptance:** Lighthouse CI in workflow with LCP <2.5s, CLS <0.1 budgets.

### ⚫ [ALL-RULES] Close §2.1 rule-coverage gaps
- **Owners:** all · **Severity:** Low · **Effort:** S
- **Why:** §2.1 has no line budget for routers (`app_router.dart` 406 lines) or for TypeScript Edge Functions (`create-shipping-label` 479 lines). Rule-coverage gap normalises drift.
- **Acceptance:** CLAUDE.md §2.1 amended with router and Edge Function caps; `§12 file_length_exempt` list reviewed (currently exempts `app_router.dart` — that's why it grew to 406 lines; remove the exemption or codify the new cap before the next refactor); `check_quality.dart` updated to enforce the new caps.

---

## Self-Assignment Index (owner-first view)

> Estimated effort per owner. Use this to plan the next sprint.

### 🔴 reso (`@MuBi2334`) — ~3 weeks
| ID | Task | Severity | Effort |
|----|------|----------|--------|
| R-39 | Deno tests for GDPR EFs (delete/export/cleanup) | **P0** | L |
| R-40 | Admin `is_admin()` SECURITY DEFINER RPC | **P0** | M |
| R-41 | Wire R-37 sanction email delivery | **P0** | S |
| R-42 | Provision `avatars` bucket (private + RLS) | **P1** | S |
| R-43 | E2E `chat_offer` integration test | **P1** | M |
| R-44 | DSA Art. 17 scam-flag transparency | P3 | M |
| R-45 | Bias eval + model card for scam ML | P3 | M |

### 🟢 belengaz (`@mahmutkaya`) — ~3 weeks
| ID | Task | Severity | Effort |
|----|------|----------|--------|
| B-56 | Deno tests for money-path EFs (7 functions) | **P0** | L |
| B-57 | OWASP ZAP `STAGING_URL` + fail-loud | **P0** | S |
| B-58 | Rate limiter fail-closed on `create-payment` | **P0** | S |
| B-59 | `check_edge_functions.sh --all` in CI | **P1** | S |
| B-60 | `pana` license check + SPDX SBOM | **P1** | S |
| B-61 | Codemagic + Apple/Play accounts | **P1** | M |
| B-62 | E2E `payment_workflow` integration test | **P1** | M |
| B-63 | E2E `shipping` integration test | **P1** | M |
| B-64 | Decompose 2 oversized repositories | P2 | S |
| B-65 | Ship App Bundle (.aab) | P2 | S |
| B-66 | CPU/memory/startup regression CI | P2 | M |
| B-67 | `SECURITY.md` (disclosure policy) | P2 | S |
| B-68 | 5 runbooks under `docs/runbooks/` | P2 | M |
| B-69 | Lighthouse CI LCP/CLS budgets | P3 | M |

### 🔵 pizmam (`@emredursun`) — ~1.5 weeks
| ID | Task | Severity | Effort |
|----|------|----------|--------|
| P-54 | E2E `listing_creation` integration test | **P1** | M |
| P-54 | Decompose 9 over-budget screens | P2 | M |
| P-55 | Decompose 3 admin widgets | P2 | S |
| P-56 | Firebase Performance custom traces | P2 | S |
| P-57 | Refresh `docs/SCREENS-INVENTORY.md` | P2 | S |
| P-58 | Pin `intl` dependency | P2 | S |

> **Note:** the E2E split (`P-54 / B-62 / B-63 / R-43`) intentionally distributes the integration-test burden so no one contributor is on the critical path. Each test is independent.

### ⚫ Cross-team
| ID | Task | Severity | Owners |
|----|------|----------|--------|
| ALL-PROC-1 | Re-open Sprint 9–10 until B-34/B-35 close | **P0** | all leads |
| ALL-LAUNCH | Build `docs/launch/CHECKLIST.md` for Weeks 21–22 | **P1** | all |
| ALL-ADR | ADR-022 review sign-off | P2 | belengaz + reso |
| ALL-RULES | Close §2.1 router + EF rule-coverage gaps | P3 | all |

---

## Priority Matrix (severity × effort)

| Priority | Issue                                                  | Impact   | Effort |
| -------- | ------------------------------------------------------ | -------- | ------ |
| **P0**   | R-39 GDPR EFs untested                                 | Critical | L      |
| **P0**   | B-56 Money-path EFs untested                           | Critical | L      |
| **P0**   | R-40 Admin `is_admin()` client-side stub               | Critical | M      |
| **P0**   | B-57 OWASP ZAP silently skipped                        | Critical | S      |
| **P0**   | B-58 Rate limiter fails open                           | High     | S      |
| **P0**   | R-41 R-37 sanction emails not delivered                | High     | S      |
| **P0**   | ALL-PROC-1 Sprint 9–10 mis-reported as 95%             | High     | S      |
| **P1**   | ALL-LAUNCH Launch sprint at 0%                         | High     | L      |
| **P1**   | R-42 `avatars` bucket missing                          | High     | S      |
| **P1**   | ALL-E2E (P-54/B-62/B-63/R-43) integration tests        | High     | L      |
| **P1**   | B-59 `check_edge_functions.sh` not in CI               | Medium   | S      |
| **P1**   | B-61 Codemagic blocked on accounts                     | High     | M      |
| **P1**   | B-60 Heuristic license; no SBOM                        | Medium   | S      |
| **P2**   | P-54/P-55/B-64 decompose §2.1 over-budget files        | Medium   | M      |
| **P2**   | B-65 Fat APK → App Bundle                              | Medium   | S      |
| **P2**   | B-67/B-68 SECURITY.md + runbooks                       | Medium   | M      |
| **P2**   | B-66 CPU/memory regression CI                          | Medium   | M      |
| **P2**   | P-56 Firebase Perf traces                              | Medium   | S      |
| **P2**   | P-57 SCREENS-INVENTORY refresh                         | Low      | S      |
| **P2**   | ALL-ADR ADR-022 reviewers                              | Low      | S      |
| **P3**   | R-44 DSA Art. 17 transparency                          | Medium   | M      |
| **P3**   | R-45 ML model card / bias eval                         | Medium   | M      |
| **P3**   | P-58 `intl: any`                                       | Low      | S      |
| **P3**   | ALL-RULES §2.1 router + EF caps                        | Low      | S      |
| **P3**   | B-69 Lighthouse LCP/CLS                                | Low      | M      |

---

## Closing Assessment

DeelMarkt's engineering quality is genuinely above what most pre-launch fintech-adjacent products achieve. The depth of CLAUDE.md, the 7 ADRs, the 94% test-to-source ratio at the unit level, and the EU regulatory awareness baked into the data model (ADR-023, DSA, EAA) all warrant credit.

But **launch readiness is a different bar than code quality**. The Edge Function test gap, the silently-skipped ZAP scan, the client-side admin guard, the fail-open rate limiter, and the unstarted launch sprint together represent enough operational risk that a soft launch in Amsterdam this sprint would be premature.

**A 2–3 week extension dedicated to the P0 bucket is the responsible path.** Tier-1 teams (Stripe, Apple, Linear) re-open sprints regularly. It is not a failure; it is the quality gate working as intended.

The companion `/preflight` audit will be added to this same PR and will produce the **launch-week go/no-go checklist** that maps these findings to App Store / Play Store / GDPR / ACM gates.

---

## Provenance & Method

- **Workflow:** `.agent/workflows/retrospective.md` v2.1.0, all 8 domains assessed
- **Method:** Two parallel `Explore` agents (security/architecture + CI/test) + Claude Opus 4.7 final synthesis
- **Evidence anchors:** every finding cites a file path, line number, or migration ID
- **Bias control:** "no defense bias" rule applied — fresh-eyes review, no minimisation
- **Sources cross-referenced:** `CLAUDE.md`, `docs/SPRINT-PLAN.md`, `docs/ARCHITECTURE.md`, `docs/adr/ADR-001..026`, `.github/workflows/*.yml`, `scripts/check_quality.dart`, `scripts/check_edge_functions.sh`, `pubspec.yaml`, all 22 `supabase/functions/*/index.ts`
