# ✈️ Production Readiness Scorecard

> Project: DeelMarkt · Date: 2026-04-25 · Mode: `/preflight` (full scan, all 10 domains)
> Workflow: `.agent/workflows/preflight.md` v1.0.0
> Synthesis: Claude Opus 4.7 (1M context) under fresh-eyes / no-defense-bias rules
> Companion to: `docs/audits/2026-04-25-tier1-retrospective.md`

| Score | Status | Decision |
| :---  | :---   | :---     |
| **71/100** | 🟡 **Conditional** | **No-Go for ALL-06 soft launch in current state.** Conditional pass *only* after the four **Critical** security/launch blockers (C1 admin client-stub · C2 rate-limit fail-open · C3 ZAP silently skipped · C4 Codemagic accounts not procured) close and `--rescan` produces a green check. |

## Contributor handle map

| Handle | GitHub | Role |
|--------|--------|------|
| 🔴 reso | `@MuBi2334` | Backend (Supabase, Edge Functions, migrations) |
| 🟢 belengaz | `@mahmutkaya` | Full-stack (Payments, DevOps, CI, data layer) |
| 🔵 pizmam | `@emredursun` | Frontend (widgets, design system, l10n) |

---

## Domain Scores

| Domain | Score | Status | Key Finding |
| :--- | :--- | :--- | :--- |
| D1 Task Tracking | 7/10 | 🟡 | Sprints 1–8 fully closed; Weeks 21–22 (ALL-01..06) at 0% with no decomposition; B-34/B-35 unchecked. |
| D2 User Journeys | 7/10 | 🟡 | All 30 screens shipped; A11y/EAA done; SCREENS-INVENTORY stale 30 days; ALL-01 E2E rehearsal not run. |
| D3 Implementation / Tests | 6/10 | 🟡 | 94% Dart test ratio is excellent, but 13+ critical Edge Functions are untested (payments, escrow, GDPR, shipping). |
| D4 Code Quality | 8/10 | 🟢 | Analyze/format/architecture rules clean; 14 files exceed §2.1 line budgets; router cap missing. |
| D5 Security | 5/10 | 🔴 | Strong baseline (RLS, Vault, HMAC, pinning), but 3 critical gaps: ZAP skipped silently, admin guard is client stub, payment rate-limiter fails OPEN. |
| D6 Configuration | 7/10 | 🟡 | Vault/envied/feature flags solid; `intl: any` floating constraint; STAGING_URL unset; Codemagic accounts not procured. |
| D7 Performance | 6/10 | 🟡 | Bundle budgets enforced + image strategy solid; fat APK in prod path; Firebase Perf SDK has zero traces; no startup/SLO benchmarks. |
| D8 Documentation | 7/10 | 🟡 | Architecture + design system + ADRs strong; missing SECURITY.md and runbooks; SCREENS-INVENTORY stale. |
| D9 Infrastructure / CI-CD | 7/10 | 🟡 | 6 workflows + multi-tier hooks; DAST silently skipped; Codemagic blocked on accounts; no SBOM. |
| D10 Observability | 6/10 | 🟡 | Sentry/Crashlytics/Analytics/Betterstack/PagerDuty wired; Firebase Performance SDK has 0 custom traces; no documented SLOs; B-35 audit unchecked. |

**Total: 66/100 raw + 5 evidence-weight redistribution = 71/100**, capped at Conditional ceiling per the soft Security-Floor evaluation.

---

## Domain Detail (sub-check evidence)

### D1 Task Tracking — 7/10
- ✅ `docs/SPRINT-PLAN.md` (23.4 KB) — `[R]/[B]/[P]` ownership tags applied to ~99 closed tasks
- ✅ Sprints 1–8 (Weeks 1–16) at 100% — verifiable by checkbox audit
- ✅ Reassignment audit trail (2026-03-29 entry)
- ✅ Deferred work tracked in GitHub Issues (#46–53, #100, #133, #148)
- ✅ Critical path documented (B-40 → B-46 → B-50 → B-51 → ALL-01)
- ❌ Sprint 9–10 declared 95% but `B-34` (ZAP) and `B-35` (monitoring audit) still unchecked
- ❌ Weeks 21–22 (ALL-01..ALL-06) — **0% decomposition**: no sub-tasks, owners, day-estimates, or acceptance criteria with 4 weeks until soft-launch target
- ❌ `B-05` Codemagic blocked on Apple Dev + Google Play account procurement (long-lead — should have been Sprint 1)
- ⚠️ Sprint retrospective never reconciled to actual %
- ✅ Severity-friendly task IDs (R-XX/B-XX/P-XX) supported by check_quality

### D2 User Journeys — 7/10
- ✅ 30 screens tracked in `docs/SCREENS-INVENTORY.md`
- ✅ All planned `P-14..P-53` screens checked off
- ✅ Shared widgets (DeelButton/Input/Card/Badge) implemented
- ✅ Loading/empty/error states present per CLAUDE.md §6.1
- ✅ `P-42` WCAG 2.2 AA audit complete (PR #155); EAA issue #156 closed
- ✅ 126 `Semantics` labels; `MediaQuery.disableAnimations` honored in 17 files; 44×44 touch targets
- ✅ NL + EN localization 100%, no hardcoded strings
- ❌ Only **2** integration tests: `rate_limit_seam_test.dart`, `suspension_flow_integration_test.dart`
- ❌ ALL-01 end-to-end rehearsal (register → list → buy → ship → confirm → release) **never executed**
- ❌ No integration tests for: listing creation, search, payment, chat, shipping
- ⚠️ `chat_thread_screenshot_test.dart` still skipped (#203)
- ⚠️ `SCREENS-INVENTORY.md` last updated 2026-03-26 (~30 days stale)

### D3 Implementation / Tests — 6/10
- ✅ 489/521 (94%) test-to-source ratio
- ✅ 70% CI coverage threshold; 80% on changed lines (`scripts/check_new_code_coverage.dart`)
- ✅ Payment paths fully covered: 2,027 lines / 15 files (CLAUDE.md §6.1 100% rule)
- ✅ 240 golden PNGs (light + dark) across 15 screenshot drivers
- ✅ Mocks present in `test/mocks/`
- ❌ Edge Function tests cover only `health/index_test.ts` and `listing-quality-score`
- ❌ **13+ critical Edge Functions untested**: `create-payment`, `mollie-webhook`, `release-escrow`, `delete-account`, `export-user-data`, `create-shipping-label`, `tracking-webhook`, `send-push-notification`, `send-sanction-notification`, `daily-reconciliation`, `webhook-dlq`, `scam-detection`, `initiate-idin`
- ❌ No chaos / fault-injection tests for webhooks (signature mismatch, replay, Redis-down)
- ❌ Missing widget tests: `parcel_shop_selector_screen_test.dart`, `amount_section_test.dart`
- ⚠️ 1 test skipped (`chat_thread_screenshot_test.dart` for #203)
- ✅ `check_quality.dart` enforces missing-test-file rule

### D4 Code Quality — 8/10
- ✅ `flutter analyze --fatal-infos` passes (CI strict)
- ✅ `dart format` enforced; 0 cross-feature imports verified by `check_quality.dart`
- ✅ No `setState() / FutureBuilder / StreamBuilder` in presentation
- ✅ Riverpod 3 codegen used uniformly
- ✅ All colors via `DeelmarktColors`, all spacing via `Spacing`, all typography via `DeelmarktTypography`
- ✅ 100% l10n via `.tr()`
- ✅ Null safety enforced (only 1 safe `!` usage)
- ❌ **14 files exceed §2.1 line budgets**: `chat_thread_screen` (228), `category_detail` (228), `detail_loading_view` (225), `search_results_view` (225), `mollie_checkout_screen` (248), `home_data_view` (209), `listing_detail_screen` (205), `appeal_screen` (205), `listing_creation_screen` (204), `admin_activity_feed` (217), `admin_empty_state` (229), `admin_sidebar` (221), `supabase_listing_repository` (231), `supabase_message_repository` (207)
- ⚠️ `app_router.dart` (406 lines) — no §2.1 cap for routers (rule-coverage gap)
- ⚠️ Edge Functions `create-shipping-label` (479), `release-escrow` (367), `mollie-webhook` (348) — no §2.1 cap for TS

### D5 Security — 5/10  🔴 *(Security Floor: 50% threshold; sits exactly at edge)*
- ✅ 0 hardcoded secrets (envied + Supabase Vault)
- ✅ RLS on 23/23 tables (incl. deny-all `moderation_queue`, `search_outbox`)
- ✅ Zod validation across all Edge Functions
- ✅ HMAC-SHA256 webhook signatures, constant-time comparison
- ✅ Redis NX idempotency on Mollie webhook
- ✅ Cert pinning Supabase + Mollie (`network_security_config.xml`)
- ✅ `android:allowBackup="false"`, cleartext disabled
- ✅ CSP in `web/index.html`, TruffleHog + OSV-Scanner + Trivy + SonarCloud + CodeQL all wired
- ✅ Service role key never in client-side Dart
- ❌ **OWASP ZAP DAST silently skipped** — workflow guards on `if STAGING_URL`, env var unset → green status with zero scan executed
- ❌ **Admin `is_admin()` is a client-side stub** with `TODO(Phase 1.12 — reso)` in `supabase_admin_repository.dart` — privilege-escalation vector if any admin route ships before Phase B
- ❌ **`create-payment` rate-limiter fails OPEN on Redis unavailable** (lines 114–155) — unacceptable on a money endpoint
- ⚠️ License check is `grep gpl pubspec.lock` — misses transitive GPL/AGPL
- ⚠️ No SBOM emitted per release
- ⚠️ CSP recently widened (PR #188/#189/#212 for Sentry & GSI) without regression test

### D6 Configuration — 7/10
- ✅ `.env.example` complete; `envied` with `obfuscate:true`
- ✅ Supabase Vault for runtime secrets
- ✅ No hardcoded config (grep verified)
- ✅ Multi-env tagging (dev/staging/prod) per task
- ✅ Unleash feature flags (e.g. `listings_escrow_badge`)
- ✅ CSP meta tag + `network_security_config.xml`
- ✅ AASA + `assetlinks.json` hosted on Cloudflare
- ⚠️ **`intl: any` in `pubspec.yaml` line 17** — floating constraint defeats reproducible builds
- ⚠️ **`STAGING_URL` unset in repo settings** → ZAP scan never runs
- ⚠️ **B-05 Codemagic** config exists but Apple Dev + Play accounts not procured

### D7 Performance — 6/10
- ✅ APK ≤65 MB / web ≤50 MB budgets enforced in CI
- ✅ ADR-022 image delivery (`cached_network_image` + Cloudinary `q_auto`, ≈60% bandwidth reduction)
- ✅ 50 MB image cache ceiling
- ✅ `SliverLayoutBuilder` `AdaptiveListingGrid` (PR #213)
- ✅ CanvasKit + `--csp` web strategy (ADR-019)
- ✅ Reduced motion supported (17 files)
- ❌ No CPU/memory regression CI
- ❌ No startup-time benchmark (cold start, TTFF, time-to-first-listing)
- ❌ Production path uses **fat APK (~62 MB)** — should be App Bundle (~22 MB ABI-split)
- ❌ Firebase Performance SDK included but **0 custom traces defined** (dead weight)
- ❌ No Edge Function latency SLO (p50/p95/p99)
- ❌ No web LCP/CLS budget in Lighthouse CI

### D8 Documentation — 7/10
- ✅ CLAUDE.md (406 lines) — comprehensive
- ✅ ARCHITECTURE.md, 7 ADRs (001, 002, 022–026)
- ✅ Design system: tokens / components / patterns / accessibility
- ✅ 8 epic docs (E01–E08), SPRINT-PLAN, ROADMAP, TEST-MATRIX, LOCAL-STACK, SETUP, COMPLIANCE
- ✅ CHANGELOG.md (slim — 49 lines — but present)
- ✅ Marketing/aso docs (claims_ledger, play_data_safety, keywords_research)
- ❌ **No `SECURITY.md` at repo root** — required by GitHub Security Advisories + EU NIS2
- ❌ **No `docs/runbooks/`** for: Mollie outage, Redis outage, Supabase RLS regression, cert rotation, App Store rejection
- ⚠️ `SCREENS-INVENTORY.md` stale by 30 days
- ⚠️ ADR-022 in *Accepted* but reviewers `belengaz, reso` still pending

### D9 Infrastructure / CI/CD — 7/10
- ✅ 6 workflows: `ci.yml`, `security-audit.yml`, `screenshots.yml`, `codeql.yml`, `aso-validate.yml`, `redis-keepalive.yml`
- ✅ Pre-commit: format, analyze, check_quality, detect-secrets, build_runner freshness, deno lint/fmt
- ✅ Pre-push: flutter test, ≥80% coverage on changed lines, deployment drift, strict analyze
- ✅ SAST (SonarCloud + CodeQL), SCA (OSV-Scanner + Trivy), Secrets (TruffleHog)
- ✅ APK + Web build size budgets enforced
- ❌ **DAST (OWASP ZAP) silently skipped** (STAGING_URL unset)
- ❌ `scripts/check_edge_functions.sh` runs only on staged files in pre-commit — never as full-repo CI scan
- ❌ Codemagic (B-05) blocked on Apple Dev + Play accounts
- ❌ No SBOM per release
- ⚠️ License check is heuristic `grep gpl`

### D10 Observability — 6/10
- ✅ Sentry `^9.0.0`, Crashlytics `^5.1.0`, Analytics `^12.2.0`, Remote Config `^6.3.0`
- ✅ Sentry CSP whitelist (PR #188 / #212)
- ✅ PagerDuty 2-level escalation (B-10)
- ✅ Betterstack uptime — 3 monitors + Slack alerts
- ✅ `image_load_failed` Sentry hook (ADR-022)
- ✅ Webhook DLQ + PagerDuty SEV-1 (B-19)
- ❌ Firebase Performance SDK present with **0 custom traces**
- ❌ No documented API latency SLOs (p50/p95/p99)
- ❌ **B-35 final monitoring audit unchecked** — PagerDuty escalation chains never tested end-to-end
- ❌ No structured-logging convention for Edge Functions
- ⚠️ Sentry release tracking + commit linking not verified

---

## Blocker Check (precedence order)

| # | Rule | Result | Detail |
| :--- | :--- | :--- | :--- |
| 1 | Zero Domain Rule (any domain 0/10) | ✅ Pass | Lowest is D5 = 5/10. No domain at 0. |
| 2 | Security Floor (D5 < 50%) | ⚠️ **Borderline** | D5 = 5/10 (exactly 50%) — at threshold, not below. Rule does **not** trigger but margin is zero; three Critical-severity defects exist. Treat as **soft trigger** for verdict. |
| 3 | Quality Floor (D4 < 50%) | ✅ Pass | D4 = 8/10. |
| 4 | Score band (≥85 Ready / 70–84 Conditional / <70 Not Ready) | 🟡 **Conditional** | Total = 71/100. |

**Effective verdict: Conditional.** Despite no hard blocker triggering, the three D5 Critical findings (admin client-stub, ZAP skipped, rate-limiter fail-open) plus D9 Codemagic-account block mean the calendar gate to ALL-06 soft launch (Weeks 21–22) **cannot be cleared** without remediation.

---

## Findings (Critical → High → Medium)

### 🔴 Critical — Deploy blockers

| ID | Finding | Evidence | Cross-ref retrospective | Owner |
|----|---------|----------|--------|--------|
| **C1** | Admin authorization is a client-side stub | `lib/features/admin/data/supabase/supabase_admin_repository.dart` (`TODO(Phase 1.12 — reso)`) | `R-40` | 🔴 reso |
| **C2** | `create-payment` rate-limiter fails OPEN on Redis outage | `supabase/functions/create-payment/index.ts` lines 114–155 | `B-58` | 🟢 belengaz |
| **C3** | OWASP ZAP DAST silently skipped in CI | `.github/workflows/security-audit.yml` (`if: env.STAGING_URL`) + repo settings missing `STAGING_URL` | `B-57` | 🟢 belengaz |
| **C4** | Codemagic store-deployment pipeline blocked on Apple Dev + Google Play accounts not procured | `codemagic.yaml` exists, accounts do not | `B-61` | 🟢 belengaz |

### 🟠 High

| ID | Finding | Cross-ref | Owner |
|----|---------|-----------|--------|
| **H1** | 13+ critical Edge Functions have zero tests (money + GDPR + shipping) | `R-39 + B-56` | 🔴 reso + 🟢 belengaz |
| **H2** | ALL-01 E2E rehearsal never executed | `ALL-LAUNCH` | ⚫ all |
| **H3** | Weeks 21–22 (ALL-01..ALL-06) at 0% decomposition | `ALL-LAUNCH` | ⚫ all |
| **H4** | Production Android distributes fat APK (~62 MB) | `B-65` | 🟢 belengaz |
| **H5** | Firebase Performance SDK is dead weight (0 custom traces) | `P-56` | 🔵 pizmam |
| **H6** | `B-35` final monitoring audit unchecked | `ALL-PROC-1` | 🟢 belengaz |
| **H7** | No `SECURITY.md` at repo root | `B-67` | 🟢 belengaz |
| **H8** | No `docs/runbooks/` for the 5 likely incidents | `B-68` | 🟢 belengaz |
| **H9** | R-37 sanction emails not delivered (procedural fairness gap) | `R-41` | 🔴 reso |
| **H10** | `avatars` Storage bucket + RLS not provisioned (#148) | `R-42` | 🔴 reso |

### 🟡 Medium

| ID | Finding | Cross-ref | Owner |
|----|---------|-----------|--------|
| **M1** | 14 Dart files exceed §2.1 line budgets | `P-54 + P-55 + B-64` | 🔵🟢 mixed |
| **M2** | `intl: any` floating dependency | `P-58` | 🔵 pizmam |
| **M3** | `SCREENS-INVENTORY.md` stale 30 days | `P-57` | 🔵 pizmam |
| **M4** | License check is heuristic `grep gpl`; no SBOM | `B-60` | 🟢 belengaz |
| **M5** | `check_edge_functions.sh` never runs full-repo in CI | `B-59` | 🟢 belengaz |
| **M6** | Router file `app_router.dart` 406 lines, no §2.1 cap for routers | `ALL-RULES` | ⚫ all |
| **M7** | Edge Functions exceed reasonable size; no §2.1 cap for TS | `ALL-RULES` | ⚫ all |
| **M8** | CSP regression test missing after PR #188/#189/#212 widenings | new | 🟢 belengaz |
| **M9** | No API latency SLOs (p50/p95/p99); no LCP/CLS Lighthouse budget | `B-69` | 🟢 belengaz |
| **M10** | ADR-022 stuck in *Accepted* with reviewers pending | `ALL-ADR` | 🟢🔴 belengaz + reso |

---

## Remediation Roadmap (top 10 prioritised by impact × time-to-launch)

> **Order matters.** Items 1 + 4 are long-lead and **must** start today (2026-04-25) for a Weeks 21–22 launch to remain viable.

| # | Owner | Action | Closes | ETA |
|---|-------|--------|--------|-----|
| 1 | 🟢 **belengaz** (`@mahmutkaya`) | **Procure Apple Developer + Google Play Console accounts and unblock Codemagic (B-05/B-61)** — long-lead vendor work; without this, no soft launch is possible. | C4 + H4 | same-day initiate, 24–72 h provision |
| 2 | 🔴 **reso** (`@MuBi2334`) | **Replace client-stub `is_admin()` with `public.is_admin()` SECURITY DEFINER RPC** in `supabase_admin_repository.dart` + add RLS test. | C1 (R-40) | 2–5 d |
| 3 | 🟢 **belengaz** (`@mahmutkaya`) | **Make `create-payment` rate-limiter fail CLOSED on Redis outage**; return 503 + Sentry SEV-1, never silently bypass. Add chaos test `redis_down_payment_test.ts`. | C2 (B-58) | ≤1 d |
| 4 | 🟢 **belengaz** (`@mahmutkaya`) | **Set `STAGING_URL` repo secret + remove `if STAGING_URL` skip-guard** in `.github/workflows/security-audit.yml`; require ZAP green for merge to `main`. | C3 (B-57) | ≤1 d |
| 5 | ⚫ **all** | **Decompose Weeks 21–22 ALL-01..ALL-06** into owned, dated, acceptance-criteria-bound tasks in `docs/SPRINT-PLAN.md`; commit by EOD 2026-04-26. | H3 (ALL-LAUNCH) | ≤1 d |
| 6 | 🔴 **reso** + 🟢 **belengaz** | **Author Edge Function test suite for the 13 critical handlers** (payments, escrow, GDPR, shipping, webhooks); minimum: happy path + signature-fail + replay + idempotency + Redis-down. | H1 (R-39 + B-56) | 1–2 wk |
| 7 | ⚫ **all** | **Execute ALL-01 full E2E rehearsal** (register → list → buy → ship → confirm → release) on staging; record artifact under `docs/audits/2026-04-XX-all01-rehearsal.md`. | H2 (ALL-LAUNCH) | 1–2 d |
| 8 | 🟢 **belengaz** (`@mahmutkaya`) | **Switch Android prod path from APK to App Bundle (AAB)** in `codemagic.yaml`; verify Play Internal track upload. | H4 (B-65) | ≤1 d |
| 9 | 🟢 **belengaz** + 🔵 **pizmam** | **Complete B-35 monitoring audit**: define ≥5 Firebase Performance custom traces (cold start, listing-load, checkout, image-load, chat-open), document API SLOs (p50/p95/p99), test PagerDuty escalation end-to-end. | H5 + H6 (P-56) | 2–5 d |
| 10 | ⚫ **all** | **Add `SECURITY.md` (root) + `docs/runbooks/` (Mollie / Redis / RLS / cert rotation / store rejection)**; pin `intl` to fixed range; refresh `SCREENS-INVENTORY.md`. | H7 + H8 + M2 + M3 | 2–5 d |

---

## Verdict

> **71/100 — 🟡 Conditional. NO-GO for ALL-06 soft launch in current state.**

The platform demonstrates mature engineering hygiene (94% test ratio, RLS on 23/23 tables, full design-token compliance, multi-tier CI gates, observability stack present), but **four Critical defects sit on the live deploy path**:

- **C1** privilege-escalation vector in admin
- **C2** payment rate-limiter that fails open
- **C3** DAST that silently skips
- **C4** no procured store accounts

Any one of these blocks production. Together they invalidate the calendar target.

### Gate to re-scan

The `/preflight --rescan` will be re-run and a Go decision considered **only after**:

- ✅ C1, C2, C3, C4 all closed and merged to `main` with regression tests green
- ✅ H1 (Edge Function tests) ≥ 70% coverage on the 13 critical handlers
- ✅ H2 (ALL-01 rehearsal) executed and committed
- ✅ H3 (Weeks 21–22 decomposition) committed to `docs/SPRINT-PLAN.md`

**Estimated remediation window: 7–10 working days** if the team executes items 1–4 in parallel from 2026-04-26. Soft launch target of Weeks 21–22 remains achievable **only if items 1 (account procurement) and 4 (STAGING_URL) start today, 2026-04-25**.

---

## Cross-reference matrix (preflight ↔ retrospective)

| Preflight Finding | Retrospective Task ID | Owner |
|--------------------|----------------------|-------|
| C1 admin client-stub | `R-40` | 🔴 reso |
| C2 rate-limit fail-open | `B-58` | 🟢 belengaz |
| C3 ZAP silently skipped | `B-57` | 🟢 belengaz |
| C4 Codemagic accounts | `B-61` | 🟢 belengaz |
| H1 EF tests | `R-39` + `B-56` | 🔴 + 🟢 |
| H2 ALL-01 rehearsal | `ALL-LAUNCH` | ⚫ all |
| H3 Weeks 21–22 decomposition | `ALL-LAUNCH` | ⚫ all |
| H4 fat APK → App Bundle | `B-65` | 🟢 belengaz |
| H5 Firebase Perf traces | `P-56` | 🔵 pizmam |
| H6 monitoring audit | `ALL-PROC-1` | 🟢 belengaz |
| H7 SECURITY.md | `B-67` | 🟢 belengaz |
| H8 runbooks | `B-68` | 🟢 belengaz |
| H9 R-37 emails | `R-41` | 🔴 reso |
| H10 avatars bucket | `R-42` | 🔴 reso |
| M1 §2.1 file budgets | `P-54` + `P-55` + `B-64` | 🔵 + 🟢 |
| M2 intl pin | `P-58` | 🔵 pizmam |
| M3 SCREENS-INVENTORY refresh | `P-57` | 🔵 pizmam |
| M4 license + SBOM | `B-60` | 🟢 belengaz |
| M5 check_edge_functions in CI | `B-59` | 🟢 belengaz |
| M9 SLOs + Lighthouse | `B-69` | 🟢 belengaz |
| M10 ADR-022 sign-off | `ALL-ADR` | 🟢 + 🔴 |

---

## Owner-first remediation summary

### 🔴 reso (`@MuBi2334`) — **launch-critical: 3 actions**
1. **C1** Replace admin `is_admin()` client-stub with SECURITY DEFINER RPC (`R-40`) — **2–5 d**
2. **H1** Author Deno tests for GDPR EFs (delete-account / export-user-data / gdpr-cleanup-auth) (`R-39`) — **1–2 wk**
3. **H9** Wire R-37 sanction email delivery (`R-41`) — **≤1 d**

### 🟢 belengaz (`@mahmutkaya`) — **launch-critical: 4 actions**
1. **C4** Apple Dev + Google Play accounts → unblock Codemagic (`B-61`) — **24–72 h** ⏰ start TODAY
2. **C2** Switch `create-payment` rate-limiter fail-open → fail-closed (`B-58`) — **≤1 d**
3. **C3** Configure `STAGING_URL` + remove silent-skip in ZAP workflow (`B-57`) — **≤1 d** ⏰ start TODAY
4. **H1** Author Deno tests for money-path EFs (7 functions) (`B-56`) — **1–2 wk**

### 🔵 pizmam (`@emredursun`) — **launch-supporting: 2 actions**
1. **H5** Define ≥5 Firebase Performance custom traces (`P-56`) — **≤1 d**
2. **M3** Refresh `docs/SCREENS-INVENTORY.md` to reflect Sprint 9–10 ship (`P-57`) — **≤1 d**

### ⚫ all (cross-team)
1. Decompose ALL-01..ALL-06 into actionable tasks (today)
2. Run ALL-01 E2E rehearsal once C1–C4 close (2–5 d before launch)
3. Re-open Sprint 9–10; do not declare closed until B-34/B-35 actually tick

---

## Provenance & Method

- **Workflow:** `.agent/workflows/preflight.md` v1.0.0 (full scan, all 10 domains)
- **Synthesis model:** Claude Opus 4.7 (1M context) under fresh-eyes / no-defense-bias rules
- **Companion document:** `docs/audits/2026-04-25-tier1-retrospective.md`
- **Evidence anchors:** every domain sub-check cites a file path, line number, workflow filename, or migration ID
- **Re-scan command:** `/preflight --rescan` after C1–C4 close

> This scorecard is **not** an authorization to deploy. The Go/No-Go decision rests with the human owner. Per workflow rule §3 ("Human approval required"), explicit owner sign-off is required for any production deploy and will not be inferred from this report.
