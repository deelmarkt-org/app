# Sprint Plan — 3-Developer Workflow

> 20 weeks to Phase 1 soft launch. Mark tasks `[x]` when complete.
> AI agents: find tasks by developer label `[R]` = reso, `[B]` = belengaz, `[P]` = pizmam.

---

## Team

| Handle | Label | Role | Owns | Branch Prefix |
|:-------|:------|:-----|:-----|:-------------|
| **reso** | `[R]` | Backend | `lib/core/services/`, `supabase/`, Edge Functions, DB migrations | `feature/reso-*` |
| **belengaz** | `[B]` | Payments/DevOps | `.github/workflows/`, `codemagic.yaml`, `lib/core/router/`, Mollie, shipping | `feature/belengaz-*` |
| **pizmam** | `[P]` | Frontend/Design | `lib/widgets/`, `lib/core/design_system/`, `lib/core/l10n/`, screens | `feature/pizmam-*` |

---

## How to Prompt the AI Agent

```
"I'm reso, work on my next task"
"I'm pizmam, continue where I left off"
"I'm belengaz, start task B-12"
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

## Sprint 1–2 (Weeks 1–4) — E07: Foundation

### reso `[R]` — Backend Infrastructure

**Branch:** `feature/reso-E07-supabase-firebase` | **Epic:** [E07](epics/E07-infrastructure.md)

- [ ] `R-01` Create Supabase project (Pro plan) — project live, dashboard accessible
- [ ] `R-02` Configure Supabase Auth (email + phone OTP) — registration works in dashboard
- [ ] `R-03` Enable RLS on all default tables — verified via SQL
- [ ] `R-04` Set up Supabase Vault — one secret stored and retrievable
- [ ] `R-05` Set up Supabase Storage — `listings-images` bucket with RLS
- [ ] `R-06` Enable Supabase Realtime — enabled on messages table (placeholder)
- [ ] `R-07` Deploy first Edge Function (health check) — `/functions/v1/health` returns 200
- [ ] `R-08` Set up Firebase project — FCM, Crashlytics, Analytics, Remote Config configured
- [ ] `R-09` Connect Firebase to Flutter — `google-services.json` + `GoogleService-Info.plist`
- [ ] `R-10` Set up Unleash (self-hosted Railway/Render) — dashboard accessible, one test flag
- [ ] `R-11` Set up Upstash Redis — connection working from Edge Function
- [ ] `R-12` Set up Sentry — error tracking receiving test events

### belengaz `[B]` — DevOps & Deep Linking

**Branch:** `feature/belengaz-E07-cicd-deeplinks` | **Epic:** [E07](epics/E07-infrastructure.md)

- [x] `B-01` Set up Cloudflare DNS for deelmarkt.com — domain resolves, SSL active
- [x] `B-02` Configure Cloudflare WAF (basic rules) — WAF enabled
- [x] `B-03` Set up Cloudinary account — API key in Supabase Vault, test upload works
- [x] `B-04` Create GitHub Actions CI workflow — lint, analyze, test, CVE scan on PR
- [ ] `B-05` Set up Codemagic — iOS (TestFlight) + Android (Play internal) builds
- [x] `B-06` Host AASA file on Cloudflare — valid JSON at `/.well-known/apple-app-site-association`
- [x] `B-07` Host `assetlinks.json` for Android — accessible at correct URL
- [x] `B-08` Implement GoRouter deep link handler — notification tap opens correct screen
- [ ] `B-09` Set up Betterstack uptime monitoring — monitors Supabase, alerts on Slack
- [ ] `B-10` Set up PagerDuty alerting — CRITICAL/HIGH/INFO tiers configured
- [x] `B-11` Configure SonarCloud SAST in CI — analysis + quality gate on PR
- [x] `B-12` Enable secret scanning — detect-secrets pre-commit + TruffleHog in CI

### pizmam `[P]` — Design System & Frontend Foundation

**Branch:** `feature/pizmam-E07-design-system` | **Epic:** [E07](epics/E07-infrastructure.md)

- [x] `P-01` Set up Plus Jakarta Sans font — renders correctly in app
- [x] `P-02` Set up Phosphor Icons package — icons render, duotone works
- [x] `P-03` Set up easy_localization (NL/EN) — language switch works, strings from JSON
- [x] `P-04` Create NL + EN string files — at least 20 common keys each
- [x] `P-05` Implement `DeelButton` (6 variants + 3 sizes) — visual matches spec, 5 states
- [ ] `P-06` Implement `DeelInput` (text, search, price, postcode) — all variants render
- [ ] `P-07` Implement `SkeletonLoader` (shimmer) — 1.5s sweep animation
- [ ] `P-08` Implement `EmptyState` widget — illustration + message + action
- [ ] `P-09` Implement `ErrorState` widget — error message + retry button
- [ ] `P-10` Implement `LanguageSwitch` (NL/EN toggle) — segmented control, instant
- [ ] `P-11` Implement GDPR consent banner — shown on first launch, preference saved
- [ ] `P-12` Set up WCAG 2.2 AA audit tooling — contrast + touch target checks in tests
- [ ] `P-13` Write widget tests for all shared components — ≥70% on `lib/widgets/`

---

## Sprint 3–4 (Weeks 5–8) — E02: Auth + E03: Payments Start

### reso `[R]` — Auth & KYC Backend

**Branch:** `feature/reso-E02-auth` | **Epic:** [E02](epics/E02-user-auth-kyc.md)

- [ ] `R-13` Supabase Auth email + phone OTP flow — user can register and verify
- [ ] `R-14` JWT refresh token handling in Dio interceptor — tokens refresh silently
- [ ] `R-15` Biometric auth (Face ID / Fingerprint) — works on iOS + Android
- [ ] `R-16` Rate-limited login (Supabase config) — blocks after 5 failed attempts
- [ ] `R-17` KYC state machine (levels 0–2) — `kyc_level` column, RLS references it
- [ ] `R-18` iDIN integration (or mock for dev) — Level 2 triggers on first listing
- [ ] `R-19` User profile table + RLS — CRUD with verification badges
- [ ] `R-20` Account deletion Edge Function (GDPR) — PII deleted in 30 days, audit log
- [ ] `R-21` Data export endpoint (GDPR portability) — JSON export of user data

### belengaz `[B]` — Payment Foundation

**Branch:** `feature/belengaz-E03-mollie-setup` | **Epic:** [E03](epics/E03-payments-escrow.md)

- [ ] `B-13` Mollie Connect merchant account setup — API keys in Vault
- [ ] `B-14` iDEAL payment flow (WebView) — test payment completes end-to-end
- [ ] `B-15` Webhook Edge Function with idempotency — Redis NX, duplicates blocked
- [ ] `B-16` HMAC-SHA256 webhook signature verification — invalid sigs rejected
- [ ] `B-17` Double-entry ledger schema — `ledger_entries` table, RLS append-only
- [ ] `B-18` Daily reconciliation Edge Function (cron) — ledger vs Mollie events
- [ ] `B-19` DLQ + PagerDuty SEV-1 on webhook failure — alert on 5th retry

### pizmam `[P]` — Auth Screens + Trust Components

**Branch:** `feature/pizmam-E02-auth-screens` | **Epic:** [E02](epics/E02-user-auth-kyc.md)

- [ ] `P-14` Onboarding screen (first launch) — language selection + value proposition
- [ ] `P-15` Registration screen (email + phone) — form validation, OTP flow
- [ ] `P-16` Login screen (email + biometric) — both flows, error states
- [ ] `P-17` Profile screen (public view) — badges, ratings placeholder, response time
- [ ] `P-18` Settings screen (language, addresses, notifications) — settings persist
- [ ] `P-19` `DeelBadge` widget (verification badges) — all 7 types render
- [ ] `P-20` `DeelAvatar` widget (with badge overlay) — avatar + badge positioning
- [ ] `P-21` `TrustBanner` widget (escrow protection) — matches spec
- [ ] `P-22` `DeelCard` — listing card (grid + list) — both variants, shimmer loading
- [ ] `P-23` KYC prompt bottom sheet (Level 1→2) — triggers on first listing

---

## Sprint 5–8 (Weeks 9–16) — E01 + E03 + E06 in Parallel

### reso `[R]` — Listings Backend

**Branch:** `feature/reso-E01-listings` | **Epic:** [E01](epics/E01-listing-management.md)

- [ ] `R-22` Listings table schema + RLS — CRUD with correct permissions
- [ ] `R-23` Category table (L1 + L2) — seeded with 8 L1 + initial L2
- [ ] `R-24` Favourites table + RLS — save/unsave/list works
- [ ] `R-25` PostgreSQL FTS (Dutch tsvector) — "fietsen" matches "fiets"
- [ ] `R-26` Listing quality score Edge Function — returns 0–100, per-field breakdown
- [ ] `R-27` Image upload Edge Function — resize + EXIF strip + ClamAV + Cloudinary
- [ ] `R-28` Location/distance query (PostGIS or haversine) — distance sorting works
- [ ] `R-29` `search_outbox` table + trigger — events on listing CRUD
- [ ] `R-30` Outbox → Redis cache invalidation — cache cleared on sold/deleted

### belengaz `[B]` — Escrow Flow + Shipping

**Branch:** `feature/belengaz-E03-escrow-flow` | **Epics:** [E03](epics/E03-payments-escrow.md) + [E05](epics/E05-shipping-logistics.md)

- [ ] `B-20` Split payment flow (buyer → escrow → seller) — commission split correct
- [ ] `B-21` 90-day escrow hold logic — funds held until confirmation or timeout
- [ ] `B-22` Escrow release on delivery confirmation — tracking event triggers release
- [ ] `B-23` 48-hour buyer confirmation window — auto-release after timeout
- [ ] `B-24` Transaction status state machine — all states work
- [ ] `B-25` PostNL Shipping V4 API integration — QR code generated after sale
- [ ] `B-26` DHL QR Service integration — DHL alternative works
- [ ] `B-27` PostNL tracking webhook — real-time tracking events received
- [ ] `B-28` PostNL postcode API (address auto-fill) — postcode → street + city

### pizmam `[P]` — Listing Screens + Widgets

**Branch:** `feature/pizmam-E01-listing-screens` | **Epic:** [E01](epics/E01-listing-management.md)

- [ ] `P-24` Listing creation screen (photo-first) — camera → form → score → publish
- [ ] `P-25` Listing detail screen (full layout) — gallery, trust banner, seller card, CTA
- [ ] `P-26` Search screen (FTS integration) — search bar + results grid + filters
- [ ] `P-27` Category browse screen — L1 horizontal scroll + L2 vertical list
- [ ] `P-28` Favourites screen — save/unsave toggle, list view
- [ ] `P-29` Home screen (buyer mode) — categories + recent + nearby
- [ ] `P-30` `ImageGallery` widget — swipe, dots, zoom, Hero transition
- [ ] `P-31` `PriceTag` widget — Euro formatting, BTW, strikethrough
- [ ] `P-32` `LocationBadge` widget — distance + pin icon
- [ ] `P-33` `EscrowTimeline` widget — horizontal stepper with states
- [ ] `P-34` `ScamAlert` widget (inline chat warning) — matches spec

---

## Sprint 9–10 (Weeks 17–20) — E04 + E05 + E06 Integration

### reso `[R]` — Messaging + Trust Backend

**Branch:** `feature/reso-E04-messaging` | **Epics:** [E04](epics/E04-messaging.md) + [E06](epics/E06-trust-moderation.md)

- [ ] `R-31` Messages table + Supabase Realtime — real-time delivery works
- [ ] `R-32` "Make an Offer" structured message type — offer with price stored
- [ ] `R-33` Seller response time calculation (cron) — average computed daily
- [ ] `R-34` FCM push notification on new message — delivered on iOS + Android
- [ ] `R-35` E06 scam detection Edge Function — flagged/clean in <1s
- [ ] `R-36` Reviews table + blind review logic — hidden until both submit
- [ ] `R-37` Account suspension/appeal tables + flow — suspend/appeal/reinstate
- [ ] `R-38` DSA notice-and-action reporting table — 24hr SLA tracked

### belengaz `[B]` — Shipping UI + Monitoring

**Branch:** `feature/belengaz-E05-shipping` | **Epic:** [E05](epics/E05-shipping-logistics.md)

- [ ] `B-29` QR code display screen (seller) — QR generated and displayed
- [ ] `B-30` Tracking timeline screen (buyer + seller) — vertical stepper, live updates
- [ ] `B-31` ParcelShop selector (PostNL VPS map) — map shows nearest locations
- [ ] `B-32` Dutch address input widget integration — 3-field auto-fill works
- [ ] `B-33` Delivery → escrow release integration — end-to-end flow works
- [ ] `B-34` OWASP ZAP weekly scan on staging — automated, results in Slack
- [ ] `B-35` Final monitoring audit — all PagerDuty alerts tested
- [ ] `B-36` Add CSP meta tag to `web/index.html` — default-src 'self', script-src, connect-src whitelist
- [ ] `B-37` Add `network_security_config.xml` with certificate pinning — pin Supabase + Mollie certs
- [ ] `B-38` Set `android:allowBackup="false"` + disable cleartext — hardened AndroidManifest

### pizmam `[P]` — Chat UI + Moderation + Polish

**Branch:** `feature/pizmam-E04-chat-screens` | **Epics:** [E04](epics/E04-messaging.md) + [E06](epics/E06-trust-moderation.md)

- [ ] `P-35` Chat conversation list screen — unread badges, response time
- [ ] `P-36` Chat thread screen — listing embed, bubbles, offer messages
- [ ] `P-37` Scam alert integration in chat — warning on flagged messages
- [ ] `P-38` Rating/review screen (post-transaction) — star + text, blind
- [ ] `P-39` Seller profile screen (public ratings) — average + reviews + badges
- [ ] `P-40` Admin moderation panel (Retool) — flagged, disputes, DSA, appeals
- [ ] `P-41` Seller/buyer mode home toggle — dashboard adapts
- [ ] `P-42` Accessibility final audit — all screens WCAG 2.2 AA
- [ ] `P-43` App Store screenshots + ASO metadata — both stores

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

## Conflict Prevention

| Rule | Details |
|:-----|:-------|
| **One owner per file** | See ownership above. Touch another dev's file → ask first. |
| **Shared widgets frozen after Sprint 2** | `lib/widgets/` changes need all-3 PR review |
| **Localisation keys** | Anyone adds to `core/l10n/*.json`. Sort alphabetically. |
| **`pubspec.yaml`** | Coordinate on Slack. reso has final say. |
| **Supabase migrations** | Only reso writes. Others request via Slack. |
| **PR size** | Max 500 lines. Smaller is better. |
| **PR review** | 1 review from another dev before merge to `dev` |
| **Daily standup** | done / doing / blocked (15 min, async Slack if remote) |
