# RUNBOOK — Mollie webhook failure

> **Owner:** belengaz (Payments / DevOps)
> **Backup owner:** reso (Edge Function + Redis idempotency)
> **Last reviewed:** 2026-04-30
> **Next scheduled review:** 2026-07-30 (90-day cadence)
> **Severity classification:** SEV-1 (active payment loss) · SEV-2 (degraded but recovering) · SEV-3 (transient or recoverable via DLQ)
> **Source of truth for code:** `supabase/functions/mollie-webhook/index.ts` · DLQ: `supabase/functions/webhook-dlq/index.ts`

This runbook is the **authoritative response procedure** when the Mollie payment webhook fails to process an event end-to-end. The webhook is on the money path — uncovered failures translate directly to ledger drift, double charges, or stuck escrow. Closes Tier-1 retrospective B-68 (1 of 5 runbooks).

---

## 1. What "the Mollie webhook" does

```
Mollie payment status change
        │
        ▼
┌──────────────────────────────────────────────────────┐
│  POST /functions/v1/mollie-webhook                    │
│  • HMAC-SHA256 signature verification (B-16)          │
│  • Zod payload validation                             │
│  • Redis NX idempotency check (B-15)                  │
│  • Fetch payment from Mollie API                      │
│  • Map status → transactions table                    │
│  • Write ledger entries (double-entry)                │
│  • Trigger downstream (escrow release, notifications) │
└──────────────────────────────────────────────────────┘
        │
        ├── success → 200 OK → Mollie marks delivered
        ├── client error (4xx) → Mollie retries with backoff up to 5×
        └── server error (5xx) → DLQ via webhook-dlq function (B-19)
```

Reference: `docs/epics/E03-payments-escrow.md` §Webhook handler.

---

## 2. Symptoms (how this surfaces)

| Symptom | Likely severity | First check |
| :--- | :--- | :--- |
| PagerDuty SEV-1 page: "Mollie webhook 5th retry failed" | **SEV-1** | DLQ table; reconciliation cron output |
| Sentry alert: high error rate in `mollie-webhook/index.ts` | SEV-2 | Sentry breadcrumbs; recent deploy log |
| Daily reconciliation cron flags ledger ≠ Mollie events | SEV-1 | Reconciliation report; ledger query |
| Customer support ticket: "I paid but transaction shows pending" | SEV-1 if recent (<1h), SEV-2 if older | Look up transaction by Mollie payment id |
| Slack alert: Redis NX failure rate > 1% | SEV-2 | Upstash dashboard; Edge Function logs |
| Test environment: webhook returning 401 / 403 | SEV-3 (likely config) | HMAC signature; service-role header on DLQ retry |

If you are paged with no symptom listed here, treat as **SEV-2 by default** and begin §3 triage.

---

## 3. Triage (do this first, before mitigation)

### 3.1 Confirm it is a real failure, not a Mollie-side outage

```
# Check Mollie status page first — saves 15 minutes if their API is degraded.
curl -s https://status.mollie.com/api/v2/summary.json | jq '.status.indicator'
```

If `indicator != "none"`, the failure is upstream. **Do not** start a code-side investigation; instead:

- Post in `#payments-incidents` Slack: "Mollie status `<indicator>` since `<timestamp>`; suspending mitigation until upstream recovers."
- Confirm DLQ is enqueueing failed deliveries (§4.3) — they will retry once upstream recovers.
- Skip to §6 (Communication).

### 3.2 Identify the failure class

```
# In Supabase dashboard → Logs → Edge Functions → mollie-webhook
# Filter to status >= 500 in the last 1 hour
```

| Log signal | Failure class | Skip to |
| :--- | :--- | :--- |
| `Invalid signature` repeated | HMAC misconfig | §4.1 |
| `Redis NX failed` repeated | Idempotency layer down | §4.2 |
| `Mollie API error (5xx)` | Upstream API degraded | §3.1 (confirm via status) |
| `Mollie API error (404)` for known payment id | Payment was deleted by Mollie or bad metadata | §4.4 |
| `Unauthorized` on DLQ retries | Service-role JWT issue | §4.5 |
| `Function timeout (>60s)` | Slow downstream (DB query / FCM) | §4.6 |
| Unknown status string from Mollie | Unrecognised payment state | §4.7 |

### 3.3 Snapshot the blast radius

Before you fix anything, capture the scope:

```sql
-- How many transactions are stuck in 'pending' that should have advanced?
select count(*), min(created_at), max(created_at)
from public.transactions
where status = 'pending'
  and created_at < now() - interval '15 minutes'
  and mollie_payment_id is not null;

-- How many DLQ entries are unprocessed?
select count(*), min(enqueued_at), max(enqueued_at)
from public.webhook_dlq
where processed_at is null
  and webhook_source = 'mollie';
```

Write the numbers in the incident channel. They are your "before" benchmark for §5 verification.

---

## 4. Mitigation by failure class

### 4.1 HMAC signature mismatch

**Cause:** Mollie webhook signing secret rotated, or signing-secret drift between staging / production.

**Mitigation:**

1. Compare the signing secret in Supabase Vault (named `mollie_webhook_secret`) to the one shown in the Mollie dashboard → Developers → Webhooks → Settings. They must match byte-for-byte.
2. If rotated by Mollie, update the Vault secret. **The Edge Function reads via the `vault_read_secret` RPC (see `supabase/functions/_shared/vault.ts`), so this is a SQL/dashboard operation — `supabase secrets set` only manages function env vars, NOT Vault entries.** Use either:
   - **Dashboard (recommended for ops):** Supabase project → Settings → Vault → locate `mollie_webhook_secret` → Edit → paste the new value → Save.
   - **SQL via service-role connection (scripted rotation):**
     ```sql
     -- Locate the secret id
     SELECT id FROM vault.secrets WHERE name = 'mollie_webhook_secret';

     -- Update in place (Supabase Vault SQL function)
     SELECT vault.update_secret(
       <secret_id>,
       '<new-value-from-mollie-dashboard>',
       'mollie_webhook_secret',
       'Mollie webhook signing secret (rotated YYYY-MM-DD)'
     );
     ```
3. The Edge Function reads the secret on every invocation via `getVaultSecret`, so no redeploy is needed; the next webhook delivery picks up the new value automatically.
4. Re-process the rejected webhooks: see §4.3 DLQ replay.

### 4.2 Redis idempotency layer down

**Cause:** Upstash Redis outage, hot-keyed instance, or misconfigured credentials.

**Mitigation:**

1. Check Upstash dashboard → connection health and command latency.
2. If Upstash itself is degraded, the webhook handler **fails closed** by design (B-58 pattern aligned). It returns 503 to Mollie, and Mollie retries with backoff. Wait for upstream recovery; do NOT hand-process events while Redis is down — duplicate processing risk.
3. If Redis credentials drifted, rotate from Upstash dashboard and update Supabase Vault key `redis_url` / `redis_token`. Same no-redeploy pattern as §4.1.
4. After Redis recovers, the Mollie retries naturally drain. DLQ entries that age beyond Mollie's retry envelope (5 attempts) need manual replay via §4.3.

### 4.3 DLQ replay (most common mitigation tail)

**When:** any case above where Mollie's retry envelope expired before the cause was fixed.

**How `webhook-dlq` actually works** (see `supabase/functions/webhook-dlq/index.ts`): the function is **batch-driven, not id-targeted**. On each invocation it scans `mollie_webhook_events WHERE processed = false AND attempts < MAX_ATTEMPTS (5)`, ordered by `created_at`, capped at 20 rows, applies per-row exponential backoff (1s → 8s) since `last_attempted_at`, and re-POSTs each event payload to `mollie-webhook` with the service-role JWT. There is **no request-body parsing** — a manual invocation is only a "tick this cron now" trigger; you cannot pick specific ids via the request body.

**Mitigation:**

1. Trigger an immediate replay run (instead of waiting for the 5-minute pg_cron tick):
   ```bash
   # Trigger one DLQ pass now. No body needed; the function ignores any payload.
   curl -X POST https://<project>.supabase.co/functions/v1/webhook-dlq \
        -H "Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>"
   ```
   Response body returns counters: `{ retried, succeeded, failed, alerted, timestamp }`.
2. The function calls `mollie-webhook` for each event with the captured `mollie_id`. Idempotency NX still applies, so duplicate replays are safe.
3. To **force-replay events that already exhausted attempts** (`attempts >= MAX_ATTEMPTS`, i.e. already PagerDuty-alerted), you must reset their state in SQL with service-role privileges first — the function will not retry them otherwise:
   ```sql
   -- Reset specific stuck events for one more retry pass
   UPDATE public.mollie_webhook_events
   SET attempts = 0, last_error = NULL, last_attempted_at = NULL, alerted_at = NULL
   WHERE id IN (<id1>, <id2>, ...) AND processed = false;
   ```
   Then trigger the function as in step 1.
4. After replay completes, re-run the §3.3 blast-radius queries — `pending > 15min` should drop to ≤ pre-incident baseline.
5. Failed replays remain in `mollie_webhook_events` with their `last_error` populated. Cross-reference via `select id, mollie_id, attempts, last_error from mollie_webhook_events where processed = false` to triage individually.

### 4.4 Mollie API 404 for known payment id

**Cause:** the `id` field in the webhook payload does not resolve in Mollie's API. Either Mollie deleted a test payment, or the payload was crafted (signature must have somehow passed — investigate).

**Mitigation:**

1. Check if the payment id matches a real `transactions.mollie_payment_id`.
2. If yes and the row is `pending`: query Mollie support; in parallel, mark the transaction as `failed_unrecoverable` and refund manually. Document in the incident channel.
3. If no: this is a security concern (signed-but-unknown id). File a `SEV-2` security incident per `SECURITY.md` — possible signing-key compromise or replay attack.

### 4.5 Unauthorized on DLQ retries (service-role JWT)

**Cause:** `verifyServiceRole` exact-match check fails. Service-role secret rotated without updating the DLQ caller.

**Mitigation:**

1. Confirm `SUPABASE_SERVICE_ROLE_KEY` in DLQ caller environment matches the dashboard value.
2. Update and re-trigger DLQ replay per §4.3.
3. Audit who rotated the service role and when — this should never be a silent operation.

### 4.6 Function timeout (>60s)

**Cause:** slow downstream — DB lock contention, FCM rate-limited, Mollie API slow.

**Mitigation:**

1. Identify the slow stage from Sentry breadcrumbs (the function emits one per stage).
2. If DB: check Supabase metrics for active queries; consider killing long transactions.
3. If FCM: not in webhook critical path — should be fire-and-forget. If blocking, treat as bug and file an issue. Mitigation: temporarily disable push notification call via Remote Config kill switch.
4. If Mollie API itself is slow: §3.1 outage check.

### 4.7 Unknown payment status string

**Cause:** Mollie added a new status value not yet mapped in `transaction-status-map.ts`.

**Mitigation:**

1. The webhook handler logs `unrecognised_mollie_status: <value>` and returns 200 (so Mollie does not retry indefinitely with a malformed payload).
2. The transaction stays in its current state. No customer impact unless this is a terminal status mismapped as transient.
3. Open a `bug` issue with the unmapped status; reso + belengaz add the mapping in a follow-up PR.
4. If the unmapped status is critical (e.g. new "fraud" tier from Mollie), trigger emergency mapping PR.

---

## 5. Verification (after mitigation)

Mitigation is not complete until **all** of the following hold:

- [ ] `transactions where status = 'pending' and created_at < now() - interval '15 minutes' and mollie_payment_id is not null` returns 0 rows
- [ ] `webhook_dlq where processed_at is null and webhook_source = 'mollie'` returns 0 rows (or only entries less than 5 minutes old, which will retry)
- [ ] `daily_reconciliation` cron next run reports zero ledger ≠ Mollie discrepancies
- [ ] No new Sentry alerts in `mollie-webhook/index.ts` for the 30 minutes following mitigation
- [ ] Customer support reports no new "I paid but" tickets in the next hour
- [ ] PagerDuty incident closed with a resolution comment linking back to the §3.2 failure class

If any verification fails, **do not close the incident** — escalate to backup owner (reso) and re-enter §3.

---

## 6. Communication (during the incident)

| Audience | Channel | When |
| :--- | :--- | :--- |
| Engineering team | `#payments-incidents` Slack | At triage start, every 30 min during mitigation, at resolution |
| Founder / leadership | DM to founder | If SEV-1 lasts > 60 min, or any monetary impact > €1k |
| Affected customers | Email via support → individual ticket reply | After resolution; never proactive en-masse before mitigation completes |
| Mollie | Mollie support ticket | Only if §4.4 (404 on known id) — possible upstream issue |
| Status page (if public) | DeelMarkt status page | SEV-1 only, with a non-technical summary |
| Regulator | Per `SECURITY.md` §6 — DPA notification within 72h **only** if user-data breach occurred | Post-incident, in coordination with reso (GDPR sign-off) |

**Hard rule:** do not promise individual customers a refund timeline before §5 verification is green. Refund commitments without verification create a worse incident.

---

## 7. Post-incident (within 5 business days)

- File a brief retrospective in `docs/audits/` named `INCIDENT-mollie-<YYYY-MM-DD>.md` covering: timeline, root cause, blast radius, mitigation, customers affected, lessons learned, action items
- Action items become GitHub issues with owners
- If the failure class was new (i.e. not in §4.1-§4.7 above), update this runbook to add it
- If the runbook was used and worked: bump `Last reviewed` only — no change required
- If the runbook was used and was wrong: fix it, and bump `Last reviewed` with a note in `docs/CHANGELOG.md`

---

## 8. Escalation contacts

| Role | Who | Channel |
| :--- | :--- | :--- |
| Primary owner | belengaz (`@mahmutkaya`) | Slack DM, PagerDuty primary |
| Backup owner | reso (`@MuBi2334`) | Slack DM, PagerDuty secondary |
| Founder (executive call) | (via belengaz) | Reserved for SEV-1 with revenue impact > €5k |
| Mollie merchant support | Per Mollie dashboard → Support | For §4.4 only |
| Supabase support | dashboard → Support → Open ticket | For Edge Function platform issues |
| Upstash Redis support | dashboard → Support | For §4.2 only |

---

## 9. Related runbooks (siblings to author next)

- `RUNBOOK-redis-outage.md` — generic Redis outage playbook (covers idempotency + rate-limit layers)
- `RUNBOOK-supabase-rls-regression.md` — RLS policy regression detection + rollback
- `RUNBOOK-cert-pinning-rotation.md` — Supabase + Mollie certificate rotation procedure
- `RUNBOOK-app-store-rejection.md` — App Store / Play Store rejection response

These are tracked under the parent Tier-1 retrospective task **B-68** (5 runbooks total). This runbook closes 1 of 5.

---

## 10. References

- Source: `supabase/functions/mollie-webhook/index.ts`
- DLQ: `supabase/functions/webhook-dlq/index.ts`
- Idempotency: `supabase/functions/_shared/idempotency.ts`
- Reconciliation: `supabase/functions/daily-reconciliation/index.ts`
- Epic: `docs/epics/E03-payments-escrow.md`
- Tier-1 retrospective: `docs/audits/2026-04-25-tier1-retrospective.md` §B-68
- Mollie webhook docs: [docs.mollie.com/payments/status-changes](https://docs.mollie.com/payments/status-changes)
- Mollie status page: [status.mollie.com](https://status.mollie.com/)
