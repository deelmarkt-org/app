# E07 — Infrastructure, CI/CD, Deep Linking & Localisation

> **Priority:** P1 — High | **Phase:** 0 (Pre-Launch) | **Est. Duration:** 5 weeks

---

## Overview

Foundation infrastructure: Supabase project, Firebase setup, CI/CD pipeline, Cloudflare DNS + deep linking, Cloudinary, Upstash Redis (idempotency + cache tiers), Unleash feature flags, localisation (NL/EN), consent management, accessibility setup, and pre-launch security.

---

## User Stories

- As a developer, I have a CI pipeline that blocks merges on test failures, coverage gaps, and CVEs
- As a developer, I can roll out features gradually and roll back instantly via Unleash feature flags
- As a user, I receive push notifications for messages, sales, and shipping updates
- As a user, tapping a notification or shared link opens the correct in-app screen
- As a user, I can use the app in Dutch or English
- As a user, I see a cookie/consent banner on first launch (GDPR)

---

## Technical Scope

### Supabase Project (1 week)
- PostgreSQL with RLS policies on all tables
- Auth configuration (email + phone OTP + biometric)
- Storage for image uploads
- Edge Functions for webhooks (Mollie, PostNL)
- **Vault for secret management** — all API keys stored here; no secrets in env vars or source code
- Realtime enabled for messaging

### Firebase (3 days)
- FCM for push notifications
- Crashlytics for crash reporting
- Analytics for user analytics (Phase 1; PostHog replaces in Phase 2)
- **Remote Config for A/B experiments and remote app configuration** (distinct from feature flags — see Unleash below)
- Performance Monitoring

### Feature Flags — Unleash (3 days)
> **ADR-013 decision: Unleash (self-hosted), not Firebase Remote Config.**
> Firebase Remote Config handles A/B experiments and remote configuration values.
> Unleash handles feature flag lifecycle: targeting rules, gradual rollouts, instant kill-switch, environment scoping.

- Unleash self-hosted (Docker on Railway or Render; ~$0–$7/mo)
- SDK: `unleash_proxy_client_flutter` or REST client
- Flag examples: `snap_to_list_enabled`, `stream_chat_migration`, `phase2_promoted_listings`
- Instant rollback: toggle off → all clients receive update within seconds
- Phase 2: Unleash Cloud (~$80/mo) when team size justifies managed service

### Deep Linking (3 days)
- iOS: `/.well-known/apple-app-site-association` on Cloudflare
- Android: `assetlinks.json` for App Links
- GoRouter deep link handler with `app_links` package
- Paths: `/listings/*`, `/users/*`, `/transactions/*`, `/shipping/*`
- **Critical:** AASA endpoint live BEFORE App Store submission

### Localisation — NL/EN (3 days)
- easy_localization package setup
- NL and EN `.arb` or JSON string files
- One-tap language switch in settings
- All UI strings externalised (no hardcoded text)
- DD-MM-YYYY date format, Euro currency formatting, +31 phone format

### CI/CD Pipeline (1 week)
- GitHub Actions (lint, test, coverage ≥70%, CVE scan, golden tests)
- Codemagic for mobile deployment (split per ABI builds)
- Performance budget gates (APK size <25MB, frame render P99 <16.67ms, cold start <2.5s)
- Blue-green deployment (Phase 1); canary 5%/20%/100% via Unleash (Phase 2)

### External Services (3 days)
- Cloudflare: DNS + SSL + CDN + WAF (free tier)
- Cloudinary: image transform + CDN (free tier)
- Upstash Redis: webhook idempotency + **multi-tier cache** (free tier):
  | Cache | TTL | Invalidation |
  |:------|:----|:-------------|
  | Listing detail | 5 min | `listing.updated`, `listing.sold`, `listing.deleted` |
  | Search results | 2 min | `listing.created`, `listing.updated` |
  | User profile | 10 min | `user.updated`, review added |
  Stale-while-revalidate pattern; events driven by `search_outbox` (E01)
- Sentry: error tracking (free tier)
- **Betterstack Free:** external uptime monitoring (independent of Supabase infra — SLA reporting)

### Consent & Accessibility (3 days)
- GDPR consent banner (Didomi CMP — IAB TCF 2.2 compliant; or simple custom implementation for MVP)
- Privacy policy and accessibility statement pages (hosted or in-app)
- WCAG 2.2 AA audit tooling setup (axe-core or manual checklist)
- Semantic labels and contrast checks integrated into CI golden tests

### Monitoring & Security (3 days)
- Crashlytics + Sentry integration
- PagerDuty alerting hierarchy (CRITICAL / HIGH / INFO) — see ARCHITECTURE.md §Alerting
- **SAST:** SonarQube in CI (merge blocker)
- **DAST:** OWASP ZAP — weekly automated scan on staging environment
- **Secret scanning:** GitHub secret scanning + **GitGuardian** (real-time alerts on accidental commits)
- External penetration test (contracted firm — must complete before App Store submission)

---

## Phase 2 — Shorebird OTA Updates

> ADR-012 decision: Shorebird for Flutter OTA hotfixes (~$200/month)

**Why:** Critical payment or trust bugs cannot wait for App Store review (typically 1–3 days). Shorebird allows deploying Dart-level code changes directly to production users within minutes.

**Phase 2 User Story:**
- As an engineer, I can deploy a critical payment bug fix to all users within 15 minutes without an App Store review cycle

**Acceptance Criteria (Phase 2):**
- Shorebird integrated into Codemagic pipeline
- OTA patch flow tested: patch built → deployed → verified on TestFlight + Play Store internal before production push
- Rollback procedure documented

---

## Acceptance Criteria

- [ ] Supabase project live with RLS on all tables
- [ ] Supabase Vault configured — all third-party API keys stored in Vault; verified by code review
- [ ] Firebase configured (FCM, Crashlytics, Analytics, Remote Config)
- [ ] Unleash feature flag service running; at least one flag exercised end-to-end
- [ ] iOS Universal Links + Android App Links working
- [ ] App available in Dutch and English with one-tap switch
- [ ] GDPR consent banner displayed on first launch
- [ ] CI blocks merges on failing gates (lint, coverage, CVEs, golden tests)
- [ ] Codemagic deploys to TestFlight + Play Store internal
- [ ] Push notifications delivered on iOS and Android
- [ ] Upstash Redis cache tiers configured (listing detail 5m, search 2m, user profile 10m)
- [ ] Betterstack (or UptimeRobot) external uptime monitoring active with Slack alerts
- [ ] PagerDuty alerting configured (CRITICAL, HIGH, INFO tiers)
- [ ] SonarQube SAST gate active in CI
- [ ] OWASP ZAP scheduled weekly scan on staging
- [ ] GitGuardian + GitHub secret scanning enabled
- [ ] Accessibility: 4.5:1 contrast + 44×44px touch targets verified
- [ ] Pre-launch pentest scheduled
- [ ] ≥70% test coverage enforced
- [x] **P-43** Fastlane installed with metadata for iOS + Android in NL + EN ✅
- [x] **P-43** 240 hero screenshots (10 × 2 locales × 2 themes × 6 devices) deterministic ✅
- [x] **P-43** App Store privacy labels YAML committed ✅
- [x] **P-43** Play Console Data Safety documented ✅
- [x] **P-43** ASO keyword research documented (40 keywords) ✅
- [x] **P-43** check_aso.dart fails on over-budget copy ✅
- [x] **P-43** check_screenshots.sh validates PII and size ✅
- [x] **P-43** CI workflow regenerates screenshots on lib/ changes ✅

---

## Dependencies

- Apple Developer account + Google Play Console
- Supabase Pro ($25/mo), Cloudflare (free), Cloudinary (free), Upstash (free)
- PagerDuty account
- Unleash self-hosted instance (Railway/Render)
- Betterstack account (free tier)
- GitGuardian account (free tier for open source; startup plan otherwise)
