# Sprint Plan — 3-Developer Workflow (Revised 2026-03-29)

> **Goal**: Real e2e flows with real data. No more mocks.
> **Timeline**: 5 weeks to soft launch readiness.
> Mark tasks `[x]` when complete. `[R]` = reso, `[B]` = belengaz, `[P]` = pizmam.

---

## Team

| Handle | Label | Role | Owns | Branch Prefix |
|:-------|:------|:-----|:-----|:-------------|
| **reso** | `[R]` | Backend | `lib/core/services/`, `supabase/`, Edge Functions, DB migrations | `feature/reso-*` |
| **belengaz** | `[B]` | Full-stack (Payments/DevOps + DB + Connected Screens) | `.github/workflows/`, `cloudflare/`, `lib/core/router/`, Mollie, shipping, data layer | `feature/belengaz-*` |
| **pizmam** | `[P]` | Frontend/Design | `lib/widgets/`, `lib/core/design_system/`, `lib/core/l10n/`, auth screens, widgets | `feature/pizmam-*` |

> **Reassignment note (2026-03-29)**: belengaz completed all `[B]` tasks and now takes DB schema tasks from reso (R-19, R-22–R-25, R-28) and connected screen tasks from pizmam (P-25, P-26, P-29) to bridge the frontend-backend gap. See §Reassignment below.

---

## How to Prompt the AI Agent

```
"I'm reso, work on my next task"
"I'm pizmam, continue where I left off"
"I'm belengaz, start task B-39"
```

The agent will:
1. Read this file
2. Find your label (`[R]`, `[B]`, or `[P]`)
3. Find the first unchecked `[ ]` task (or the specific task ID)
4. Read the relevant epic doc
5. Create/switch to your branch
6. Only modify files within your ownership scope

---

## Convention Rules

> **All contributors** (human and AI) MUST follow these conventions:

| Rule | Convention |
|:-----|:----------|
| **Document Storage** | **Do NOT auto-store** plans, audits, or assets. Present them inline for review. Only archive to `docs/archives/emre/` (gitignored, local-only) when the user **explicitly requests it**. Subfolders: `sprint-implementation-plans/`, `audits/`, `assets/`. **NEVER** move or archive existing `docs/` files unless the user explicitly requests it. |
| **Branch Naming** | Follow prefix convention: `feature/{handle}-E{NN}-{area}`. |
| **Pull Requests** | Run `/pr` workflow before every PR. Local pre-flight (format, analyze, test) + sync with target branch. All 4 CI checks MUST pass before merge. |

---

## ✅ Sprint 1–2 (Weeks 1–4) — COMPLETED: E07 Foundation

### reso `[R]` — Backend Infrastructure

- [x] `R-01` Create Supabase project (Pro plan) — project live, dashboard accessible
- [x] `R-02` Configure Supabase Auth (email + phone OTP) — registration works in dashboard
- [x] `R-03` Enable RLS on all default tables — verified via SQL
- [x] `R-04` Set up Supabase Vault — one secret stored and retrievable
- [x] `R-05` Set up Supabase Storage — `listings-images` bucket with RLS
- [x] `R-06` Enable Supabase Realtime — enabled on messages table (placeholder)
- [x] `R-07` Deploy first Edge Function (health check) — `/functions/v1/health` returns 200
- [x] `R-08` Set up Firebase project — FCM, Crashlytics, Analytics, Remote Config configured
- [x] `R-09` Connect Firebase to Flutter — `google-services.json` + `GoogleService-Info.plist`
- [x] `R-10` Set up Unleash (self-hosted Railway/Render) — dashboard accessible, one test flag
- [x] `R-11` Set up Upstash Redis — connection working from Edge Function
- [x] `R-12` Set up Sentry — error tracking receiving test events

### belengaz `[B]` — DevOps & Deep Linking

- [x] `B-01` Set up Cloudflare DNS for deelmarkt.com — domain resolves, SSL active
- [x] `B-02` Configure Cloudflare WAF (basic rules) — WAF enabled
- [x] `B-03` Set up Cloudinary account — API key in Supabase Vault, test upload works
- [x] `B-04` Create GitHub Actions CI workflow — lint, analyze, test, CVE scan on PR
- [ ] `B-05` Set up Codemagic — iOS (TestFlight) + Android (Play internal) builds ⚠️ Needs Apple Dev + Google Play accounts
  > **Android build note:** CI uses a fat APK (build-only check). Production builds must use `--split-per-abi` or App Bundle:
  > ```
  > # Option 1 — App Bundle (Play Store splits automatically, recommended):
  > flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
  >
  > # Option 2 — Split APK (produces 3 separate APKs):
  > flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/debug-info
  > # → app-armeabi-v7a-release.apk (~20 MB) — older devices
  > # → app-arm64-v8a-release.apk  (~22 MB) — modern devices (95% of users)
  > # → app-x86_64-release.apk     (~23 MB) — emulators
  > ```
  > Users download only the slice for their device (~22 MB instead of ~62 MB fat APK).
- [x] `B-06` Host AASA file on Cloudflare — valid JSON at `/.well-known/apple-app-site-association`
- [x] `B-07` Host `assetlinks.json` for Android — accessible at correct URL
- [x] `B-08` Implement GoRouter deep link handler — notification tap opens correct screen
- [x] `B-09` Set up Betterstack uptime monitoring — 3 monitors active, Slack alerts
- [x] `B-10` Set up PagerDuty alerting — 2-level escalation configured
- [x] `B-11` Configure SonarCloud SAST in CI — analysis + quality gate on PR
- [x] `B-12` Enable secret scanning — detect-secrets pre-commit + TruffleHog in CI
- [ ] `B-13` Close GH #162 — TestFlight reviewer fixture & runbook
  > **Phase A (code, this PR `chore/gh162-deliver-dryrun-runbook`):**
  > - [x] Idempotent Supabase seed migration for reviewer profile/listing/transaction/thread (auth-user provisioning gated on operator runbook)
  > - [x] `_checkReviewInformation` promoted from warning → error in `scripts/check_aso.dart` + unit test
  > - [x] `scripts/check_appstore_reviewer.sh` + weekly `appstore-reviewer-healthcheck.yml`
  > - [x] `docs/runbooks/RUNBOOK-appstore-reviewer.md`
  >
  > **Phase B (operational, post-merge — belengaz):**
  > - [x] Provision both `auth.users` rows via Supabase Auth Admin REST API per runbook §3 — sentinel UUIDs `aa162162-…0001` / `aa162162-…0002` created 2026-05-01, both `email_confirmed`
  > - [x] Apply seed migration to production — all 6 healthcheck invariants pass (`is_appstore_reviewer` fn, 2 auth.users, 2 level2 profiles, listing active+escrow_eligible, transaction `paid`, ≥2 messages)
  > - [ ] Store credentials in 1Password "App Store reviewer" (testing stage — chat-leaked password to be rotated before live)
  > - [ ] Wire `ASC_DEMO_USER` / `ASC_DEMO_PASSWORD` into Codemagic global vars (blocked by B-05 Codemagic setup)
  > - [ ] Run `bundle exec fastlane ios deliver_dry_run`, archive log, link from #162 close comment (blocked by B-05)
  > - [ ] Close #162 (blocked by B-05 — Codemagic + Apple Dev account)

### pizmam `[P]` — Design System & Frontend Foundation

- [x] `P-01` Set up Plus Jakarta Sans font — renders correctly in app
- [x] `P-02` Set up Phosphor Icons package — icons render, duotone works
- [x] `P-03` Set up easy_localization (NL/EN) — language switch works, strings from JSON
- [x] `P-04` Create NL + EN string files — at least 20 common keys each
- [x] `P-05` Implement `DeelButton` (6 variants + 3 sizes) — visual matches spec, 5 states
- [x] `P-06` Implement `DeelInput` (text, search, price, postcode) — all variants render
- [x] `P-07` Implement `SkeletonLoader` (shimmer) — 1.5s sweep animation
- [x] `P-08` Implement `EmptyState` widget — illustration + message + action
- [x] `P-09` Implement `ErrorState` widget — error message + retry button
- [x] `P-10` Implement `LanguageSwitch` (NL/EN toggle) — segmented control, instant
- [x] `P-11` Implement GDPR consent banner — shown on first launch, preference saved
- [x] `P-12` Set up WCAG 2.2 AA audit tooling — contrast + touch target checks in tests
- [x] `P-13` Write widget tests for all shared components — ≥70% on `lib/widgets/`

---

## ✅ Sprint 3–4 (Weeks 5–8) — COMPLETED: E02 Auth + E03 Payments

### reso `[R]` — Auth & KYC Backend

**Branch:** `feature/reso-E02-auth` | **Epic:** [E02](epics/E02-user-auth-kyc.md)

- [x] `R-13` Supabase Auth email + phone OTP flow — user can register and verify *(fully implemented; 308 tests pass)*
- [x] `R-14` JWT refresh token handling — tokens refresh silently via Supabase SDK native session management (no custom Dio interceptor needed; app uses Supabase Flutter SDK throughout)
- [x] `R-15` Biometric auth (Face ID / Fingerprint) — works on iOS + Android *(implemented in `AuthRepositoryImpl.loginWithBiometric`)*
- [x] `R-16` Rate-limited login (Supabase config) — blocks after 5 failed attempts *(configured in `supabase/config.toml` `[auth.rate_limit]` section)*
- [x] `R-17` KYC state machine (levels 0–2) — `kyc_level` column, RLS references it *(`kyc_level` enum + index in migration; `CheckKycRequiredUseCase` logic; `KycPromptNotifier` VM)*
- [x] `R-18` iDIN integration (or mock for dev) — Level 2 triggers on first listing *(PR #132)*
- [x] `R-20` Account deletion Edge Function (GDPR) — PII deleted in 30 days, audit log *(done by belengaz)*
- [x] `R-21` Data export endpoint (GDPR portability) — JSON export of user data *(PR #132)*

### belengaz `[B]` — Payment Foundation (COMPLETED)

- [x] `B-13` Mollie Connect merchant account setup — API keys in Vault
- [x] `B-14` iDEAL payment flow (WebView) — test payment completes end-to-end
- [x] `B-15` Webhook Edge Function with idempotency — Redis NX, duplicates blocked
- [x] `B-16` HMAC-SHA256 webhook signature verification — invalid sigs rejected
- [x] `B-17` Double-entry ledger schema — `ledger_entries` table, RLS append-only
- [x] `B-18` Daily reconciliation Edge Function (cron) — ledger vs Mollie events
- [x] `B-19` DLQ + PagerDuty SEV-1 on webhook failure — alert on 5th retry

### pizmam `[P]` — Auth Screens + Trust Components

**Branch:** `feature/pizmam-E02-auth-screens` | **Epic:** [E02](epics/E02-user-auth-kyc.md)

- [x] `P-14` Onboarding screen (first launch) — language selection + value proposition ✅ PR #28
- [x] `P-15` Registration screen (email + phone) — form validation, OTP flow ✅ PR #40
- [x] `P-16` Login screen (email + biometric) — both flows, error states ✅ PR #43
- [x] `P-17` Profile screen (public view) — badges, ratings placeholder, response time ✅ PR #45
- [x] `P-18` Settings screen (language, addresses, notifications) — settings persist ✅ PR #45
- [x] `P-19` `DeelBadge` widget (verification badges) — all 7 types render ✅ PR #45
- [x] `P-20` `DeelAvatar` widget (with badge overlay) — avatar + badge positioning ✅ PR #45
- [x] `P-21` `TrustBanner` widget (escrow protection) — matches spec ✅ PR #45
- [x] `P-22` `DeelCard` — listing card (grid + list) — both variants, shimmer loading ✅ PR #45
- [x] `P-23` KYC prompt bottom sheet (Level 1→2) — triggers on first listing ✅ PR #45

### Deferred Items from PR #45 (Tracked as GitHub Issues)

> These were identified during Tier-1 audit and PR review. Each has a GitHub Issue with owner.

| Issue | Task | Owner | Blocked By | Sprint |
|:------|:-----|:------|:-----------|:-------|
| [#46](https://github.com/deelmarkt-org/app/issues/46) | `[R]` Implement SupabaseReviewRepository | reso | R-36 reviews table | 9–10 |
| [#47](https://github.com/deelmarkt-org/app/issues/47) | ~~`[R]` Implement SupabaseSettingsRepository **(P0 launch blocker)**~~ | belengaz | — | ✅ PR #57 |
| [#48](https://github.com/deelmarkt-org/app/issues/48) | `[R]` Wire iDIN to Edge Function | reso | R-18 iDIN integration | 3–4 |
| [#49](https://github.com/deelmarkt-org/app/issues/49) | `[R]` 30-day soft-delete grace period | reso | — | 5–8 |
| [#50](https://github.com/deelmarkt-org/app/issues/50) | ~~`[P]` Wire address form navigation in Settings~~ | pizmam | — | ✅ PR #149 |
| [#51](https://github.com/deelmarkt-org/app/issues/51) | ~~`[P]` Wire sell screen navigation from empty listings~~ | pizmam | P-24 | ✅ PR #149 |
| [#52](https://github.com/deelmarkt-org/app/issues/52) | ~~`[P]` Wire listing detail navigation from profile~~ | pizmam | B-51 | ✅ PR #149 |
| [#53](https://github.com/deelmarkt-org/app/issues/53) | ~~`[P]` Wire avatar picker navigation~~ | pizmam | — | ✅ PR #149 |

---

## Sprint 5–8 (Weeks 9–16) — E01 Listings + E03 Escrow + Data Layer

### reso `[R]` — Listings Backend (Edge Functions + Outbox)

**Branch:** `feature/reso-E01-listings` | **Epic:** [E01](epics/E01-listing-management.md)

- [x] `R-26` Listing quality score Edge Function — returns 0–100, per-field breakdown *(done by belengaz, PR #105 — Dart↔TS parity enforced by pre-commit)*
- [x] `R-27` Image upload Edge Function — Cloudmersive virus scan + Cloudinary (strip EXIF + WebP) ✅ PR #105 (EF) + PR #106 (service) + PR #111 (upload-on-pick queue)
- [x] `R-29` `search_outbox` table + trigger — events on listing CRUD ✅ PR #135
- [x] `R-30` Outbox → Redis cache invalidation — cache cleared on sold/deleted ✅ PR #135

### belengaz `[B]` — DB Schemas + Data Layer + Connected Screens

**Branch:** `feature/belengaz-E01-data-layer` | **Epics:** [E01](epics/E01-listing-management.md) + [E03](epics/E03-payments-escrow.md)

> **Reassigned from reso**: R-19, R-22, R-23, R-24, R-25, R-28 (DB schemas)
> **Reassigned from pizmam**: P-25, P-26, P-29 (connected screens)

**Phase A — DB Foundation (Week 1): ✅ COMPLETED**
- [x] `B-39` User profiles table + RLS — CRUD with verification badges *(was R-19)*
- [x] `B-40` Listings table + RLS — CRUD with correct permissions, FK to transactions *(was R-22)*
- [x] `B-41` Categories table + seed data (8 L1 + initial L2) *(was R-23)*
- [x] `B-42` Favourites table + RLS — save/unsave/list works *(was R-24)*
- [x] `B-43` PostgreSQL FTS (Dutch tsvector) — "fietsen" matches "fiets" *(was R-25)*
- [x] `B-44` Location/distance query (haversine) — distance sorting works *(was R-28)*

**Phase B — Flutter Data Layer (Week 2):**
- [x] `B-45` DTOs: ListingDto, CategoryDto, UserDto — fromJson/toJson for Supabase ✅ PR #29
- [x] `B-46` `SupabaseListingRepository` — implements `ListingRepository` against real DB ✅ PR #29
- [x] `B-47` `SupabaseCategoryRepository` — implements `CategoryRepository` against real DB ✅ PR #29
- [x] `B-48` `SupabaseUserRepository` — implements `UserRepository` against real DB ✅ PR #29
- [x] `B-49` Provider wiring — Riverpod overrides to swap mock ↔ Supabase repos by env ✅ PR #29

**Phase C — Connected Screens (Week 3):**
- [x] `B-50` Home screen (buyer mode) — categories + recent + nearby, real Supabase data *(was P-29)*
- [x] `B-51` Listing detail screen — gallery, trust banner, seller card, CTA, deep linked *(was P-25)*
- [x] `B-52` Search screen — FTS integration, results grid + filters *(was P-26)*

**Escrow + Shipping (COMPLETED):**
- [x] `B-20` Split payment flow (buyer → escrow → seller) — commission split correct
- [x] `B-21` 90-day escrow hold logic — funds held until confirmation or timeout
- [x] `B-22` Escrow release on delivery confirmation — tracking event triggers release
- [x] `B-23` 48-hour buyer confirmation window — auto-release after timeout
- [x] `B-24` Transaction status state machine — all states work
- [x] `B-25` PostNL Shipping V4 API integration — QR code generated after sale
- [x] `B-26` DHL QR Service integration — DHL alternative works
- [x] `B-27` PostNL tracking webhook — real-time tracking events received
- [x] `B-28` PostNL postcode API (address auto-fill) — postcode → street + city

### pizmam `[P]` — Listing Widgets + Creation Screen

**Branch:** `feature/pizmam-E01-listing-screens` | **Epic:** [E01](epics/E01-listing-management.md)

- [x] `P-24` Listing creation screen (photo-first) — camera → form → score → publish
- [x] `P-27` Category browse screen — L1 horizontal scroll + L2 vertical list ✅ PR #65
- [x] `P-28` Favourites screen — save/unsave toggle, list view ✅ PR #65
- [x] `P-30` `ImageGallery` widget — swipe, dots, zoom, Hero transition ✅ PR #66
- [x] `P-30-wire` Wire `ImageGallery` into `DetailImageGallery` via `overlayBuilder` ✅ PR #99
- [x] `P-31` `PriceTag` widget — Euro formatting, BTW, strikethrough ✅ PR #66
- [x] `P-31-wire` Wire `PriceTag` into `DeelCard`, `DetailInfoSection`, `ListingCard`; add `originalPriceInCents` to `ListingEntity` ✅ PR #99
  - ⚠ **Deferred `[R]`:** `listings.original_price_cents` DB column not yet created. DTO field is forward-compatible (nullable). Tracked via [#100](https://github.com/deelmarkt-org/app/issues/100) item 3. reso to open migration ticket when discount feature is scoped.
- [x] `P-32` `LocationBadge` widget — distance + pin icon
- [x] `P-32-wire-detail` Migrate `_LocationBlock` in `DetailInfoSection` to `LocationBadge(variant: detail, showMapPlaceholder: true)` ✅ PR #101
- [x] `P-33` `EscrowTimeline` widget — horizontal stepper with states
- [x] `P-33a` Wire `EscrowTimeline.onStepTapped` in `TransactionDetailScreen` — step-detail modal with timestamp per `patterns.md:50` ✅ PR #101
- [x] `P-34` `ScamAlert` widget (inline chat warning) — matches spec

---

## Sprint 9–10 (Weeks 17–20) — E04 Messaging + E06 Trust + Polish

### reso `[R]` — Messaging + Trust Backend

**Branch:** `feature/reso-E04-messaging` | **Epics:** [E04](epics/E04-messaging.md) + [E06](epics/E06-trust-moderation.md)

- [x] `R-31` Messages table + Supabase Realtime — real-time delivery works *(done by reso (mahmutkaya))*
- [x] `R-32` "Make an Offer" structured message type — offer with price stored
- [x] `R-33` Seller response time calculation (cron) — average computed daily *(PR #89)*
- [x] `R-34` FCM push notification on new message — delivered on iOS + Android *(PR #94)*
- [x] `R-35` E06 scam detection Edge Function — flagged/clean in <1s
- [x] `R-36` Reviews table + blind review logic — hidden until both submit *(PR #98)*
- [x] `R-37` Account suspension/appeal tables + flow — suspend/appeal/reinstate *(PR #102)* **[backend-only — UI tracked as P-53]**
  > **Email follow-up:** Sanction email notifications are not included in R-37. Email delivery via Supabase SMTP / Resend will be tracked as a separate task once the email provider is configured.
- [x] `R-38` DSA notice-and-action reporting table — 24hr SLA tracked *(PR #103)*
- [ ] `R-44` DSA Art. 17 transparency for scam-detection — Tier-1 retrospective P3 (post-launch acceptable)
  > **UI portion:** ✅ shipped via PR #256 (`ScamFlagStatementOfReasons` widget + 19 tests + l10n + suspension-gate spec doc).
  > **Backend portion:** `scam_flags` table + `get_active_scam_flag` RPC pending (reso). Wiring tracked as [#259](https://github.com/deelmarkt-org/app/issues/259).
  > **Composition a11y test:** tracked as [#260](https://github.com/deelmarkt-org/app/issues/260) (depends on #259).

### belengaz `[B]` — Message Data Layer + Monitoring + Security

**Branch:** `feature/belengaz-E04-connectors` | **Epics:** [E04](epics/E04-messaging.md) + [E05](epics/E05-shipping-logistics.md)

- [x] `B-53` `SupabaseMessageRepository` — implements `MessageRepository` against real DB *(PR #96)*
- [x] `B-54` Wire shipping/transaction screens to router — replace remaining `_Placeholder` widgets
- [x] `B-55` Wire all Supabase repositories to existing screens — replace mock data everywhere
- [x] `B-34` OWASP ZAP weekly scan on staging — automated, results in Slack
  > Workflow: `.github/workflows/zap-scan.yml` (Mon 07:00 UTC + manual). Skips cleanly until repo variable `ZAP_SCAN_TARGET_URL` is set — flip on once staging is deployed.
- [x] `B-35` Final monitoring audit — all PagerDuty alerts tested
  > Synthetic-event sender: `scripts/audit_monitoring_alerts.sh` (4 alerts: webhook-DLQ SEV-1, reconciliation crit/warn, escrow force-release). Quarterly procedure: `docs/runbooks/RUNBOOK-monitoring-audit.md`. Dry-run verified 2026-05-01; live `--fire` run is operator-driven (wakes on-call).

**Completed:**
- [x] `B-29` QR code display screen (seller) — QR generated and displayed
- [x] `B-30` Tracking timeline screen (buyer + seller) — vertical stepper, live updates
- [x] `B-31` ParcelShop selector (PostNL VPS map) — map shows nearest locations
- [x] `B-32` Dutch address input widget integration — 3-field auto-fill works
- [x] `B-33` Delivery → escrow release integration — end-to-end flow works
- [x] `B-36` Add CSP meta tag to `web/index.html` — default-src 'self', script-src, connect-src whitelist
- [x] `B-37` Add `network_security_config.xml` with certificate pinning — pin Supabase + Mollie certs
- [x] `B-38` Set `android:allowBackup="false"` + disable cleartext — hardened AndroidManifest
- [x] `P-46` Dynamic OG meta tags + crawler pre-rendering — Cloudflare Worker *(assigned to belengaz)*

### pizmam `[P]` — Chat UI + Profile + Moderation + Polish

**Branch:** `feature/pizmam-E04-chat-screens` | **Epics:** [E04](epics/E04-messaging.md) + [E06](epics/E06-trust-moderation.md)

- [x] `P-35` Chat conversation list screen — unread badges, response time ✅ PR #71
- [x] `P-36` Chat thread screen — listing embed, bubbles, offer messages ✅ PR #71
- [x] `P-37` Scam alert integration in chat — warning on flagged messages ✅ PR #75
- [x] `P-38` Rating/review screen (post-transaction) — star + text, blind ✅ PR #75
- [x] `P-39` Seller profile screen (public ratings) — average + reviews + badges ✅ PR #75
- [x] `P-40` Admin moderation panel — Phase A ✅ PR #110
- [x] `P-41` Seller/buyer mode home toggle — dashboard adapts ✅ PR #107
- [x] `P-42` Accessibility final audit — all screens WCAG 2.2 AA ✅ PR #155 merged + EAA blockers resolved (issue #156 closed via feature/pizmam-a11y-darkmode-followup)
- [x] `P-43` App Store screenshots + ASO metadata — both stores ✅ PR #161 (dark-mode chat thread design added as follow-up — closes issue #164)
- [x] `P-44` Social login (Google + Apple Sign-In) — native flow (iOS ASAuth + Android google_sign_in) + web redirect, `user_profiles` auto-trigger, Apple HIG button ✅ PR #159
- [x] `P-45` Flutter Web performance budget & CanvasKit strategy ✅ PR #14
- [x] `P-47` Dark mode implementation & validation ✅ PR #157
- [x] `P-48` ADR-019 PWA strategy document ✅ PR #14
- [x] `P-49` Responsive shell validation (4 breakpoints, 840px nav switch) ✅ PR #14
- [x] `P-50` GoRouter auth guard + splash screen + `/onboarding` route ✅ PR #14
- [x] `P-51` Mock data layer (5 entities + 4 repository interfaces + 4 mock implementations) ✅ PR #14
- [x] `P-52` Web error boundary + font loading strategy ✅ PR #14
- [x] `P-53` Suspension gate + appeal screen — auth guard shows suspension screen (type/reason/expires), appeal form with 14-day window indicator ✅ PRs #152–#153

---

## Weeks 21–22 — Integration + Launch

All developers:

- [ ] `ALL-01` End-to-end flow testing (register → list → buy → ship → confirm → release)
- [ ] `ALL-02` Penetration test remediation
- [ ] `ALL-03` Bug fixes from internal testing
- [ ] `ALL-04` Seed 500+ listings manually
- [ ] `ALL-05` App Store + Play Store submission
- [ ] `ALL-06` Phase 1 soft launch: invite-only Amsterdam

---

## Reassignment Details (2026-03-29)

### Why

belengaz completed all `[B]` tasks. The biggest bottleneck is the **zero connection between frontend and backend** — 0 Supabase repositories, no listings/users/categories DB tables, all screens use mock data. belengaz bridges this gap.

### What moved

| Original | New Owner | Tasks | Reason |
|----------|-----------|-------|--------|
| reso → belengaz | `B-39` to `B-44` | R-19, R-22, R-23, R-24, R-25, R-28 (DB schemas) | belengaz proved migration skills (transactions, shipping). Reso focuses on auth + Edge Functions. |
| pizmam → belengaz | `B-50` to `B-52` | P-25, P-26, P-29 (connected screens) | belengaz built shipping screens in same pattern. These need real data wiring. |
| new | `B-45` to `B-49` | DTOs, Supabase repos, provider wiring | Nobody owned the "connector" layer. |
| new | `B-53` to `B-55` | Message repo, screen wiring | Continuing the connector pattern. |

### What stayed

| Dev | Keeps | Reason |
|-----|-------|--------|
| **reso** | R-13 to R-18 (auth), R-20/R-21 (GDPR), R-26/R-27 (EFs), R-29/R-30 (outbox), R-31 to R-38 (messages/trust) | Auth flows need deep Supabase Auth expertise. Edge Functions are reso's strength. |
| **pizmam** | P-14 to P-23 (auth UI + widgets), P-24/P-27/P-28 (creation + browse + favourites), P-30 to P-43 (specialized widgets + chat + polish) | All auth UI, shared widgets, and specialized screens stay with frontend owner. |

### Critical Path

```
B-40 (listings table) → B-46 (SupabaseListingRepo) → B-50 (home screen) → B-51 (listing detail) → ALL-01 (e2e)
```

**B-40 is Day 1, Hour 1.** Everything depends on the listings table existing.

### Parallel Tracks

```
Week 1: belengaz (DB schemas) | reso (auth) | pizmam (widgets)
Week 2: belengaz (repos+DTOs) | reso (auth) | pizmam (widgets)
Week 3: belengaz (screens)    | pizmam (auth screens) | reso (Edge Functions)
Week 4: pizmam (creation)     | reso (messages)       | belengaz (message repo + wiring)
Week 5: pizmam (chat+profile) | reso (reviews+trust)  | belengaz (monitoring + security)
```

---

## Conflict Prevention

| Rule | Details |
|:-----|:-------|
| **One owner per file** | See ownership above. Touch another dev's file → ask first. |
| **Shared widgets frozen after Sprint 2** | `lib/widgets/` changes need all-3 PR review |
| **Localisation keys** | Anyone adds to `core/l10n/*.json`. Sort alphabetically. |
| **`pubspec.yaml`** | Coordinate on Slack. reso has final say. |
| **Supabase migrations** | belengaz and reso both write. Coordinate timestamps to avoid conflicts. |
| **PR size** | Max 500 lines. Smaller is better. |
| **PR review** | 1 review from another dev before merge to `dev` |
| **Daily standup** | done / doing / blocked (15 min, async Slack if remote) |
