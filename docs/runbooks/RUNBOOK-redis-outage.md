# RUNBOOK — Upstash Redis outage

> **Owner:** belengaz (DevOps / Infrastructure)
> **Backup owner:** reso (Edge Function consumers)
> **Last reviewed:** 2026-04-30
> **Next scheduled review:** 2026-07-30 (90-day cadence)
> **Severity classification:** SEV-1 (payment-path or GDPR-path blocked) · SEV-2 (cache miss / search slowdown) · SEV-3 (transient connection blips)
> **Source of truth for code:** `supabase/functions/_shared/redis.ts` · health probe: `supabase/functions/redis-health/index.ts`

This runbook is the **authoritative response procedure** when Upstash Redis is degraded or unavailable. Redis is on the critical path for **idempotency** (Mollie webhook, GDPR exports, image upload), **rate limiting** (`create-payment`), and **cache invalidation** (search outbox). A degraded Redis shifts behaviour from cached/idempotent to either fail-closed 503 (correct) or duplicate-processing (incorrect, depending on consumer). Closes Tier-1 retrospective B-68 (2 of 5).

---

## 1. What Redis does at DeelMarkt

```
Edge Function consumers (9+):
  ├── create-payment             → rate limiting (B-58 fail-closed)
  ├── mollie-webhook             → NX idempotency (B-15)
  ├── delete-account             → idempotency
  ├── export-user-data           → idempotency
  ├── image-upload-process       → quota / dedup
  ├── initiate-idin              → session cache
  ├── process-search-outbox      → cache invalidation (R-30)
  ├── send-push-notification     → dedup
  └── redis-health               → SET/GET probe
                │
                ▼
          ┌────────────────────────────┐
          │  Upstash Redis (REST API)  │
          │  UPSTASH_REDIS_REST_URL     │
          │  UPSTASH_REDIS_REST_TOKEN   │
          └────────────────────────────┘
```

TTL contracts (per `supabase/functions/_shared/redis.ts:29-34`):
- Listing detail cache: 5 min
- Search results cache: 2 min
- User profile cache: 10 min
- Idempotency keys: 24 hours

Reference: `docs/epics/E07-infrastructure.md` §Redis · `docs/ARCHITECTURE.md` §Caching layer.

---

## 2. Symptoms (how this surfaces)

| Symptom | Likely severity | First check |
|:---|:---|:---|
| PagerDuty SEV-1 page: "create-payment fail-closed (B-58)" | **SEV-1** | Upstash dashboard (§3.1) |
| Sentry alert: spike in `Redis SET/GET failed (HTTP 5xx)` errors across multiple EFs | **SEV-1** | Upstash status page; Edge Function logs |
| `redis-health` cron returns non-200 | **SEV-2** | redis-health logs |
| Search results stale > 2 min after listing change | **SEV-2** | search outbox processor logs |
| Mollie webhook returns 503 to Mollie ("idempotency layer down") | **SEV-1** | mollie-webhook logs (cross-reference `RUNBOOK-mollie-webhook-failure.md` §4.2) |
| Customer support: "I can't pay" recurring tickets | **SEV-1** | rate-limiter Redis probe |
| Single transient `Redis SET failed` then recovery | **SEV-3** | Upstash latency dashboard |

If you are paged with no symptom listed here, treat as **SEV-2 by default** and begin §3 triage.

---

## 3. Triage (do this first, before mitigation)

### 3.1 Confirm it is a real failure, not a transient blip

```bash
# Probe Upstash via the project's own redis-health Edge Function
# Returns 200 + {set: 'OK', get: '<probe-value>'} on success, 5xx on failure.
curl -s -H "Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>" \
     https://<project>.supabase.co/functions/v1/redis-health | jq
```

If 200 OK → the issue may have been a transient blip; check Sentry breadcrumbs to confirm whether errors stopped. If errors stopped, **classify SEV-3** and complete §6 communication only — no mitigation needed.

If non-200 → continue.

### 3.2 Check Upstash status page

```
https://status.upstash.com/
```

If Upstash itself is degraded, the failure is upstream. Post in `#payments-incidents` Slack: "Upstash status `<indicator>` since `<timestamp>`; suspending mitigation until upstream recovers." Skip to §6.

### 3.3 Identify the failure class

| Log signal | Failure class | Skip to |
|:---|:---|:---|
| `Redis SET/GET failed (HTTP 503/504)` | Upstash backend outage | §3.2 confirm + §4.1 |
| `Redis SET/GET failed (HTTP 401/403)` | Credential drift | §4.2 |
| `Redis SET/GET failed (HTTP 429)` | Rate limit on Upstash plan | §4.3 |
| Connection timeout / DNS failure | Network partition | §4.4 |
| Single 5xx among many 200s | Transient — see §3.1 | (no mitigation) |

### 3.4 Snapshot the blast radius

```bash
# In Supabase dashboard → Logs → Edge Functions, filter to status >= 500
# in the last 30 minutes across these functions:
#   create-payment, mollie-webhook, delete-account, export-user-data,
#   image-upload-process, initiate-idin, process-search-outbox,
#   send-push-notification

# Also run blast-radius queries:
```

```sql
-- How many transactions stuck in 'pending' due to webhook idempotency failures?
SELECT count(*) FROM public.transactions
WHERE status = 'pending'
  AND created_at < now() - interval '15 minutes'
  AND mollie_payment_id IS NOT NULL;

-- How many DLQ entries unprocessed?
SELECT count(*), min(enqueued_at), max(enqueued_at)
FROM public.mollie_webhook_events
WHERE processed = false;
```

Write the numbers in the incident channel. They are your "before" benchmark for §5 verification.

---

## 4. Mitigation by failure class

### 4.1 Upstash backend outage

**Cause:** Upstash service is down for our region.

**Mitigation:**

1. **Do nothing destructive while Redis is down.** The fail-closed pattern (B-58) protects correctness on the payment path:
   - `create-payment` returns 503 with `Retry-After: 30` — Mollie + clients retry naturally
   - `mollie-webhook` returns 503 — Mollie retries with backoff
   - GDPR functions (`delete-account`, `export-user-data`) fail-closed — operator must re-trigger after recovery
2. Wait for Upstash recovery (status page driven). Subscribe to status updates.
3. **DO NOT** hand-process payment events while Redis is down — duplicate-processing risk is regulator-level for ledger drift.
4. After recovery, drain DLQ + GDPR queue per their respective runbooks (`RUNBOOK-mollie-webhook-failure.md` §4.3 for webhook DLQ).

### 4.2 Credential drift (401/403 from Redis)

**Cause:** Upstash rotated the access token, or `UPSTASH_REDIS_REST_TOKEN` was changed in Supabase Vault without coordination.

**Mitigation:**

1. Read the current token from Upstash dashboard → Settings → REST API token.
2. Update the Vault entries `UPSTASH_REDIS_REST_URL` and `UPSTASH_REDIS_REST_TOKEN`. **Use the same path as Mollie webhook secret rotation:**
   - Dashboard: Supabase project → Settings → Vault → locate the entry → Edit → Save
   - SQL alternative (service-role connection):
     ```sql
     SELECT id FROM vault.secrets WHERE name = 'UPSTASH_REDIS_REST_TOKEN';
     SELECT vault.update_secret(<id>, '<new-token>', 'UPSTASH_REDIS_REST_TOKEN', 'rotated YYYY-MM-DD');
     ```
3. Edge Functions read on every invocation via `getRedisCredentials()` (per `_shared/redis.ts:14-25`), so no redeploy is needed.
4. Run §3.1 health probe to confirm.

### 4.3 Rate limit on Upstash plan (429)

**Cause:** Sustained traffic exceeds Upstash's free / paid plan ceiling.

**Mitigation:**

1. Check Upstash dashboard → Usage. Confirm we are hitting plan limits, not a per-second burst.
2. Short term: nothing to do; the rate-limit window resets on Upstash's clock. Sentry will quiet down within the window.
3. Medium term: upgrade Upstash plan (operator decision; budget impact ~€5–25/month). Update `docs/COMPLIANCE.md` cost ledger if changed.
4. Long term: review TTL contracts in `_shared/redis.ts:29-34` — are we caching too eagerly? Audit `process-search-outbox` invalidation pattern (R-30).

### 4.4 Network partition / DNS failure

**Cause:** Supabase Edge Functions cannot reach the Upstash REST URL.

**Mitigation:**

1. Probe DNS from a Supabase Edge Function shell or Supabase-hosted SQL (this is hard — Supabase doesn't expose shell). Use `redis-health` as a synthetic probe instead.
2. If DNS resolution is intermittent: file Supabase support ticket (network issue between Supabase and Upstash regions); no code-side fix possible.
3. Behaviour during partition: same as §4.1 — fail-closed pattern protects correctness; await connectivity recovery.

---

## 5. Verification (after mitigation)

Mitigation is not complete until **all** of the following hold:

- [ ] `redis-health` Edge Function returns 200 with `{set: "OK", get: "<probe>"}`
- [ ] No new Sentry alerts in `_shared/redis.ts` consumers for 30 minutes
- [ ] `create-payment` fail-closed alerts cleared in PagerDuty
- [ ] `mollie_webhook_events WHERE processed = false AND attempts < 5` returns 0 rows older than 5 minutes (DLQ drained)
- [ ] `transactions WHERE status = 'pending' AND mollie_payment_id IS NOT NULL AND created_at < now() - interval '15 minutes'` returns 0 rows
- [ ] PagerDuty incident closed with a resolution comment linking back to the §3.3 failure class

If any verification fails, **do not close the incident** — escalate to backup owner (reso) and re-enter §3.

---

## 6. Communication (during the incident)

| Audience | Channel | When |
|:---|:---|:---|
| Engineering team | `#payments-incidents` Slack | At triage start, every 30 min during mitigation, at resolution |
| Founder / leadership | DM to founder | If SEV-1 lasts > 60 min, or any monetary impact > €1k |
| Affected customers | Email via support → individual ticket reply | After resolution; never proactive en-masse before mitigation completes |
| Upstash | Upstash support ticket | Only if §4.1 backend outage AND status page silent |
| Status page (if public) | DeelMarkt status page | SEV-1 only, with a non-technical summary |
| Regulator | Per `SECURITY.md` §6 — DPA notification within 72h **only** if user-data breach occurred (none expected from Redis outage) | Post-incident only if applicable |

**Hard rule:** do not promise individual customers a refund timeline before §5 verification is green.

---

## 7. Post-incident (within 5 business days)

- File a brief retrospective in `docs/audits/` named `INCIDENT-redis-<YYYY-MM-DD>.md` covering: timeline, root cause, blast radius, mitigation, customers affected, lessons learned, action items
- Action items become GitHub issues with owners
- If the failure class was new (i.e. not in §4.1-§4.4 above), update this runbook to add it
- Update `docs/CHANGELOG.md` if the runbook was modified

---

## 8. Escalation contacts

| Role | Who | Channel |
|:---|:---|:---|
| Primary owner | belengaz (`@mahmutkaya`) | Slack DM, PagerDuty primary |
| Backup owner | reso (`@MuBi2334`) | Slack DM, PagerDuty secondary |
| Founder | (via belengaz) | Reserved for SEV-1 with revenue impact > €5k |
| Upstash support | dashboard → Support | For §4.1 only |
| Supabase support | dashboard → Support → Open ticket | For §4.4 network/DNS issues |

---

## 9. Related runbooks (siblings under B-68)

- [`RUNBOOK-mollie-webhook-failure.md`](RUNBOOK-mollie-webhook-failure.md) — webhook fails when Redis is down (this runbook is its §4.2 dependency)
- `RUNBOOK-supabase-rls-regression.md` — RLS policy regression detection + rollback (closes B-68 3/5)
- `RUNBOOK-cert-pinning-rotation.md` — cert rotation procedure (B-68 4/5, pending)
- `RUNBOOK-app-store-rejection.md` — App Store rejection response (B-68 5/5, pending)

---

## 10. References

- Source: `supabase/functions/_shared/redis.ts`
- Health probe: `supabase/functions/redis-health/index.ts`
- Idempotency: `supabase/functions/_shared/idempotency.ts`
- Epic: `docs/epics/E07-infrastructure.md` §Redis
- Tier-1 retrospective: `docs/audits/2026-04-25-tier1-retrospective.md` §B-68
- Upstash docs: [docs.upstash.com](https://docs.upstash.com/)
- Upstash status: [status.upstash.com](https://status.upstash.com/)
- Redis SRE practices: [sre.google/sre-book/managing-incidents](https://sre.google/sre-book/managing-incidents/)
