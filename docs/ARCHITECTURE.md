# DeelMarkt — Technical Architecture

> Trust-first Dutch P2P marketplace | Flutter + Supabase | **MVP cost: ~€25-35/mo**

---

## Tech Stack

| Layer | Service | Cost |
|:------|:--------|:-----|
| Frontend | Flutter 3.x + Dart 3.x (iOS + Android) | — |
| Backend + DB + Auth + Storage | Supabase Pro (PostgreSQL + Edge Functions + Realtime) | $25/mo |
| Push + Crashes + Analytics | Firebase (FCM, Crashlytics, Analytics, Remote Config) | $0 |
| Feature Flags | Unleash (self-hosted on Railway/Render) | $0-7/mo |
| Payments | Mollie Connect (iDEAL only for MVP) | per-tx |
| CDN + DNS + WAF | Cloudflare (free tier) | $0 |
| Cache + Webhook Idempotency | Upstash Redis (free tier) | $0 |
| Image CDN + EXIF strip | Cloudinary (free tier) | $0 |
| Error Tracking | Sentry (free tier) | $0 |
| Uptime Monitoring | Betterstack (free tier) | $0 |

---

## Flutter Architecture

**Clean Architecture + MVVM + Riverpod 3** — feature-first folder structure:

- **Presentation Layer** — Views + ViewModels (Riverpod Notifiers)
- **Domain Layer** — Use cases, entities, repository interfaces (pure Dart)
- **Data Layer** — Repository implementations, DTOs, Supabase adapters

### Key Packages

| Purpose | Package |
|:--------|:--------|
| State Management | Riverpod 3 (@riverpod code generation) |
| Navigation | GoRouter + app_links (deep linking) |
| HTTP Client | Dio (interceptors, retry, auth tokens) |
| Local Storage | Hive or Isar |
| Localisation | easy_localization (NL/EN; DE/FR Phase 3) |
| Testing | flutter_test, mockito, alchemist (golden), patrol (E2E) |

---

## Backend — Supabase

Supabase is the single backend platform. It provides PostgreSQL, Auth, Storage, Edge Functions, and Realtime. A custom backend is only considered when Edge Functions become a bottleneck — triggered by pain, not a calendar date.

### Architecture Diagram

```
Cloudflare (CDN + WAF + DNS) — deelmarkt.com
         │
Supabase (PostgreSQL + Auth + Edge Functions + Storage + Realtime)
         │
    ┌────┴─────────────────────────────┐
    │          External Services        │
    │  Mollie │ FCM │ Cloudinary        │
    │  Sentry │ Upstash Redis           │
    └──────────────────────────────────┘
```

### Search Strategy

**Phase 1 (0–5K MAU): PostgreSQL Full-Text Search** — built into Supabase, zero cost.

```sql
-- Dutch FTS with weighted ranking
ALTER TABLE listings ADD COLUMN search_vector tsvector
  GENERATED ALWAYS AS (
    setweight(to_tsvector('pg_catalog.dutch', coalesce(title, '')), 'A') ||
    setweight(to_tsvector('pg_catalog.dutch', coalesce(description, '')), 'B')
  ) STORED;

CREATE INDEX listings_search_idx ON listings USING GIN (search_vector);
```

Dutch stemming works: "fietsen" matches "fiets". No typo tolerance — sufficient for 2K listings.

**Phase 2 (5K+ MAU): Meilisearch** — add when typo tolerance and autocomplete are needed. Self-host on Railway (~$15-20/mo) or Cloud ($30/mo).

### Webhook Idempotency (Mollie)

```typescript
// Supabase Edge Function
const idempotencyKey = `mollie:webhook:${payload.id}`;
const isNew = await redis.set(idempotencyKey, '1', 'EX', 86400, 'NX');
if (!isNew) return new Response('Already processed', { status: 200 });
await processPaymentEvent(payload);
```

Retry: 1s → 2s → 4s → 8s → DLQ → PagerDuty SEV-1.

### Double-Entry Escrow Ledger

```sql
CREATE TABLE ledger_entries (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  transaction_id  UUID NOT NULL REFERENCES transactions(id),
  idempotency_key TEXT NOT NULL UNIQUE,
  debit_account   TEXT NOT NULL,
  credit_account  TEXT NOT NULL,
  amount_cents    INTEGER NOT NULL,
  currency        CHAR(3) NOT NULL DEFAULT 'EUR',
  created_at      TIMESTAMPTZ DEFAULT now()
);

-- Append-only: no UPDATE or DELETE
ALTER TABLE ledger_entries ENABLE ROW LEVEL SECURITY;
CREATE POLICY no_update ON ledger_entries FOR UPDATE USING (false);
CREATE POLICY no_delete ON ledger_entries FOR DELETE USING (false);
```

Daily reconciliation: ledger count vs Mollie event count. Mismatch → SEV-1.

### Cache Strategy

| Cache | TTL | Invalidation |
|:------|:----|:-------------|
| Listing detail | 5 min | `listing.updated/sold/deleted` |
| Search results | 2 min | `listing.created/updated` |
| User profile | 10 min | `user.updated`, review added |

Upstash Redis with stale-while-revalidate.

---

## Deep Linking

Universal Links (iOS) + App Links (Android) via GoRouter. **Must be live before App Store submission.**

```json
// /.well-known/apple-app-site-association (hosted on Cloudflare)
{
  "applinks": {
    "details": [{
      "appID": "TEAMID.nl.deelmarkt.app",
      "paths": ["/listings/*", "/users/*", "/transactions/*", "/shipping/*"]
    }]
  }
}
```

---

## Observability

| Pillar | Tool | Cost |
|:-------|:-----|:-----|
| Crash Reporting | Firebase Crashlytics | Free |
| Error Tracking | Sentry | Free |
| Performance | Firebase Performance Monitoring | Free |
| Analytics | Firebase Analytics (Phase 1) → PostHog (Phase 2) | Free |
| Feature Flags | Unleash (self-hosted) | Free (~$0-7/mo hosting) |
| A/B Experiments | Firebase Remote Config | Free |
| Uptime | Betterstack Free | Free |
| Secret Scanning | GitHub secret scanning + GitGuardian | Free |
| SAST | SonarQube (CI blocker) | Free |
| DAST | OWASP ZAP (weekly on staging) | Free |
| Payment Audit | Supabase logs + Mollie dashboard + ledger reconciliation | Free |

### Alerting

- **CRITICAL (PagerDuty):** Payment error rate >1%, ledger mismatch, webhook DLQ, crash rate <99%
- **HIGH (PagerDuty 15min):** P95 latency >1s, startup >4s, connection pool >80%
- **INFO (Slack):** Deploy success, DAU milestone, new app review

### Incident Severity

| SEV | Definition | Response |
|:----|:-----------|:---------|
| 1 | Payment failure / platform down | 5 min, CTO leads |
| 2 | Critical feature broken | 15 min |
| 3 | Degradation | 1 hour |
| 4 | Cosmetic | Next sprint |

---

## CI/CD

- **CI:** GitHub Actions (lint, test, coverage ≥70%, CVE scan, golden tests)
- **Deploy:** Codemagic (split per ABI, TestFlight + Play Store internal)
- **Strategy:** Blue-green (Phase 1) → canary via Unleash (Phase 2+)
- **Backup:** Supabase Pro daily backups (7-day retention)

### Performance Gates

| Gate | Threshold |
|:-----|:----------|
| APK size | < 25 MB |
| Frame render P99 | < 16.67ms (60fps) |
| Cold start | < 2.5s |
| Widget test coverage | ≥ 70% |
| Dependency CVEs | 0 |

---

## SLOs

| Metric | Target |
|:-------|:-------|
| Crash-free sessions | ≥ 99.5% |
| Payment flow completion | 99.99% |
| Search P95 latency | < 500ms |
| App cold start | < 2.5s |
| FCM delivery rate | ≥ 98% |

**Policy:** When payment error budget is 50% consumed, halt payment module feature releases.

---

## Scaling Path

| Trigger | Action |
|:--------|:-------|
| 5K+ MAU, need typo-tolerant search | Add Meilisearch ($15-30/mo); Phase 4: Elasticsearch at 10M+ listings |
| 1K+ MAU chat users | Migrate to Stream Chat SDK |
| Edge Functions too limiting | Custom backend on Railway (NestJS/Serverpod/FastAPI) |
| 50K+ MAU, need advanced analytics | Self-host PostHog on Railway |
| Cross-border expansion | Add deelmarkt.eu with Cloudflare geo-routing |

---

## Architecture Decision Records

| # | Decision | Rationale |
|:--|:---------|:----------|
| 1 | Flutter over React Native | Rendering consistency, payment security, long-term stability |
| 2 | Supabase as single backend | DB + Auth + Storage + Functions + Realtime in one; $25/mo |
| 3 | Mollie Connect as PSP | iDEAL €0.32 flat; Dutch-native; split payments; 90-day escrow |
| 4 | PostgreSQL FTS → Meilisearch → Elasticsearch | 3-stage: free built-in FTS (Phase 1) → Meilisearch for typo tolerance (Phase 2) → ES for compound words at 10M+ listings (Phase 4) |
| 5 | Firebase for push/crashes/analytics | Free tier for FCM, Crashlytics, Analytics, Remote Config (A/B experiments) |
| 6 | Progressive KYC (5 levels) | Reduces friction; iDIN/itsme at Level 2 for sellers |
| 7 | Upstash Redis for idempotency | Serverless; free tier; exactly-once payments |
| 8 | Double-entry escrow ledger | PSD2 compliance; append-only; daily reconciliation |
| 9 | Holding BV + Operations BV | IP protection; international expansion without restructuring |
| 10 | GoRouter + app_links | Deep linking critical for conversion; AASA before App Store |
| 11 | WCAG 2.2 Level AA | EAA mandated; build once correctly |
| 12 | Cloudinary for images | EXIF stripping (GDPR), WebP/AVIF, free tier covers 5K MAU |
| 13 | Cloudflare free tier | CDN + WAF + DDoS at zero cost |
| 14 | Single domain for MVP | Multi-domain routing is premature optimisation |
| 15 | Supabase Realtime for chat | Single platform; migrate to Stream Chat at ~1K MAU |
| 16 | Custom backend only on pain | Supabase handles 50K+ MAU; defer migration decision |
| 17 | Unleash for feature flags (not Firebase Remote Config) | Self-hosted = full GDPR control; audit trail; environment scoping; instant kill-switch. Remote Config handles A/B experiments only |
| 18 | Shorebird for OTA hotfixes (Phase 2) | Critical payment/trust bugs deployed in minutes without App Store review; ~$200/mo |
| 19 | PWA: online-first with offline app shell | CanvasKit WASM requires network for first load. Flutter's default Service Worker caches static assets (cache-first for return visits). Custom Workbox deferred to Phase 5 — default SW handles 90% of cases. No full offline mode (marketplace needs fresh data). PWA installable via manifest.json. |
| 20 | `wasm-unsafe-eval` in CSP for CanvasKit | CanvasKit uses `WebAssembly.compileStreaming()` which requires `wasm-unsafe-eval` in `script-src`. Without it, Flutter web shows white screen. `--csp` build flag removes `eval()` but WASM compilation still needs this directive. |
| 21 | Entity equality by ID (not freezed) | Existing entities use manual `==`/`hashCode` by ID. Consistent pattern, minimal code-gen. Revisit `freezed` if entity count exceeds 15. `equatable` available as dependency if needed. |
