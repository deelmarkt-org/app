# RUNBOOK — Supabase RLS regression

> **Owner:** reso (Backend / DB)
> **Backup owner:** belengaz (Edge Function consumers, healthchecks)
> **Last reviewed:** 2026-04-30
> **Next scheduled review:** 2026-07-30 (90-day cadence)
> **Severity classification:** SEV-1 (cross-tenant data exposure) · SEV-2 (admin scope leak / scoped query mismatch) · SEV-3 (cosmetic policy mismatch with no exploit path)
> **Source of truth for code:** `supabase/migrations/**` · healthcheck: `scripts/check_appstore_reviewer.sh`

This runbook is the **authoritative response procedure** when Supabase Row-Level Security (RLS) policies are detected to be missing, regressed, or bypassed. RLS is the primary data-access security boundary at DeelMarkt — a regression is a **GDPR Art. 32 (security of processing)** incident, not a bug. Closes Tier-1 retrospective B-68 (3 of 5).

---

## 1. What RLS does at DeelMarkt

Per CLAUDE.md §9: *"All tables MUST have RLS policies — no exceptions."* RLS scopes every query at the database level so that:

- **Authenticated users** see only their own rows (or rows they have a relationship with — e.g. `messages` where they are sender or recipient)
- **Service-role connections** bypass RLS for privileged operations (Edge Functions, cron jobs, admin RPCs)
- **Anon role** sees only explicitly public rows (e.g. `categories`, public profile fields)

Tables protected by RLS (verified against `supabase/migrations/`):

| Domain | Tables |
|:---|:---|
| Identity / KYC | `user_profiles`, `auth.users` (Supabase-managed), `gdpr_deletion_queue` |
| Listings | `listings`, `categories`, `favourites`, `search_outbox` |
| Transactions | `transactions`, `ledger_entries`, `mollie_webhook_events`, `shipping_labels`, `tracking_events` |
| Messaging | `conversations`, `messages` |
| Trust & Safety | `account_sanctions`, `reviews`, `moderation_queue`, `dsa_reports` |
| Audit | `audit_logs` (append-only, service_role insert) |

Special filters (must hold in every analytics view per CLAUDE.md §14):

- `is_appstore_reviewer(user_id) IS NOT TRUE` — excludes reviewer fixture rows from product metrics

Reference: `docs/COMPLIANCE.md` §RLS, `docs/ARCHITECTURE.md` §Security · `CLAUDE.md` §9 + §14.

---

## 2. Symptoms (how this surfaces)

| Symptom | Likely severity | First check |
|:---|:---|:---|
| Customer support: "I see another user's listing/message/transaction in my account" | **SEV-1** | Confirm reproduction; freeze the affected table |
| `appstore-reviewer-healthcheck.yml` workflow fails (CLAUDE.md §14 invariants broken) | **SEV-1 or SEV-2** | Read healthcheck output; identify which invariant |
| Sentry: spike in `42501 — permission denied for table` errors after a recent migration | **SEV-2** | Recent migration audit |
| Analytics dashboards show reviewer-fixture rows (CLAUDE.md §14 rule 4) | **SEV-2** | Find the view missing `is_appstore_reviewer` filter |
| `pg_policies` audit shows policy missing on a table flagged in §1 | **SEV-1 if SELECT**, SEV-2 if INSERT/UPDATE/DELETE | Re-add policy |
| Penetration test report: forged JWT returns rows | **SEV-1** | Engage incident commander |
| Cron job that should run as service_role hits RLS errors | **SEV-3** (cron broken, no data leak) | Verify cron auth (`verifyServiceRole`) |

If you are paged with no symptom listed here, treat as **SEV-2 by default** and begin §3 triage.

**Hard stop:** if §1-symptom matches "cross-tenant data exposure", **freeze writes to the affected table within 5 minutes** while triaging — see §4.5.

---

## 3. Triage (do this first, before mitigation)

### 3.1 Confirm scope of the regression

Run the policy audit against production via service-role connection:

```sql
-- Tables that have RLS DISABLED (should be empty for non-Supabase-managed tables)
SELECT schemaname, tablename FROM pg_tables
WHERE schemaname = 'public' AND rowsecurity = false
  AND tablename NOT LIKE 'spatial_%';

-- Tables that have RLS enabled but ZERO policies (lockout — every access denied except service_role)
SELECT t.tablename
FROM pg_tables t
LEFT JOIN pg_policies p ON p.tablename = t.tablename AND p.schemaname = t.schemaname
WHERE t.schemaname = 'public' AND t.rowsecurity = true
GROUP BY t.tablename
HAVING count(p.policyname) = 0;

-- Policies that allow USING (true) — likely accidental "anyone can read"
SELECT schemaname, tablename, policyname, cmd, qual
FROM pg_policies
WHERE qual ILIKE '%true%' AND schemaname = 'public';

-- Run the §14 healthcheck programmatically
\! bash scripts/check_appstore_reviewer.sh
```

### 3.2 Identify the failure class

| Audit signal | Failure class | Skip to |
|:---|:---|:---|
| RLS disabled on a `public.*` table | Policy dropped (DROP TABLE + recreate without RLS) | §4.1 |
| RLS enabled but no policies (lockout) | Migration error — table created without policies | §4.2 |
| Policy permits `USING (true)` on user-owned data | Over-permissive policy | §4.3 |
| `appstore-reviewer-healthcheck.yml` fixture invariants broken | §14 fixture corruption | §4.4 |
| Cross-tenant SELECT confirmed via reproduction | Active data exposure | §4.5 (FREEZE) |
| Service-role being called from anon-user context | SECURITY DEFINER misuse | §4.6 (links to R-40) |
| Analytics view missing `is_appstore_reviewer` filter | View regression (CLAUDE.md §14 rule 4) | §4.7 |

### 3.3 Snapshot the blast radius

```sql
-- For SEV-1 cross-tenant exposure: when did the regression land?
-- Find the migration applied closest before the first known exposure
SELECT name, executed_at FROM supabase_migrations.schema_migrations
ORDER BY executed_at DESC LIMIT 20;

-- Are audit_logs intact? (They have their own RLS; if compromised the
-- whole investigation is harder)
SELECT count(*), min(created_at), max(created_at)
FROM public.audit_logs
WHERE created_at > now() - interval '24 hours';
```

Write the findings in the incident channel. **Do not paste actual user data** — only counts, table names, migration names.

---

## 4. Mitigation by failure class

### 4.1 RLS disabled on a `public.*` table

**Cause:** A migration that recreates the table forgot to re-enable RLS (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`).

**Mitigation:**

1. Hotfix migration: re-enable RLS and re-add the policies the table should have:
   ```sql
   ALTER TABLE public.<table> ENABLE ROW LEVEL SECURITY;
   -- Re-add the policies from the original migration (find via `git log`)
   CREATE POLICY <name> ON public.<table> FOR <action> USING (...);
   ```
2. Apply hotfix immediately via `supabase db push` (operator-driven; service-role required).
3. Verify with §3.1 policy audit.
4. Continue to §5.

### 4.2 RLS enabled but no policies (lockout)

**Cause:** Migration enabled RLS but forgot to add policies — table is now inaccessible to authenticated users (only service_role can read). This is **closed-fail** — safer than open-fail.

**Mitigation:**

1. Identify what the policies SHOULD be — read the table's spec in `docs/epics/` or the migration's commit message.
2. Hotfix migration adds the missing policies.
3. Apply + verify.
4. Continue to §5.

### 4.3 Over-permissive policy

**Cause:** Policy uses `USING (true)` or a similarly broad qualifier where it should scope by `auth.uid()` or relationship.

**Example exploit pattern:**
```sql
-- WRONG — every authenticated user sees every other user's data
CREATE POLICY messages_read ON public.messages
  FOR SELECT TO authenticated USING (true);

-- CORRECT — only conversation participants
CREATE POLICY messages_read ON public.messages
  FOR SELECT TO authenticated
  USING (sender_id = auth.uid() OR recipient_id = auth.uid());
```

**Mitigation:**

1. **FREEZE writes to the table** (see §4.5) until policy is corrected.
2. Hotfix migration replaces the over-permissive policy.
3. Apply + verify with reproduction (forge a non-owner JWT and confirm 0 rows returned).
4. Determine if any data was exposed during the regression window; if yes → **GDPR Art. 33 notification within 72h** of awareness (see §6).

### 4.4 §14 reviewer fixture invariants broken

**Cause:** Sentinel UUIDs (`aa162162-…`) drifted, or `is_appstore_reviewer()` function was modified without updating consumers.

**Mitigation:**

1. Read `RUNBOOK-appstore-reviewer.md` §2 (Sentinel UUIDs) for canonical IDs.
2. If a sentinel was changed: revert the migration that changed it; recreate fixture if necessary via `bash scripts/provision_appstore_reviewer.sh`.
3. If `is_appstore_reviewer()` was modified: verify SQL logic against the migration that defines it (`20260425135427_seed_appstore_reviewer_account.sql`).
4. Re-run `bash scripts/check_appstore_reviewer.sh` until all 6 invariants pass.

### 4.5 Active data exposure — FREEZE protocol

**Cause:** Cross-tenant SELECT confirmed via reproduction.

**Mitigation (executed in this order):**

1. **Freeze writes (within 5 minutes):**
   ```sql
   -- Drop INSERT/UPDATE/DELETE policies temporarily; service-role still works
   -- This stops new exposure while keeping the system queryable for triage.
   -- DO NOT drop SELECT policies — that prevents users from seeing their own data,
   -- which is worse than the leak (denial of service vs information disclosure).
   ALTER POLICY <write_policy_name> ON public.<table> WITH CHECK (false);
   ```
2. Engage incident commander (founder + reso) — escalate to SEV-1.
3. Identify the exposure window from `audit_logs` and `pg_stat_statements`.
4. Apply hotfix migration (per §4.1-§4.3 as appropriate).
5. Lift the write freeze after verification.
6. **GDPR Art. 33 notification triggered** — see §6.

### 4.6 SECURITY DEFINER misuse

**Cause:** A function declared `SECURITY DEFINER` is callable from anon/authenticated context and bypasses RLS in a way that exposes data. Cross-references R-40 (admin `is_admin()` SECURITY DEFINER RPC).

**Mitigation:**

1. Identify the offending function:
   ```sql
   SELECT proname, prosecdef, proacl
   FROM pg_proc WHERE prosecdef = true AND pronamespace = 'public'::regnamespace;
   ```
2. For each: confirm the function has `SET search_path = ''` and a fully-qualified body (CLAUDE.md §9 + Supabase advisory). If not, this is also a **search-path hijacking risk**.
3. Restrict execution: `REVOKE ALL ON FUNCTION public.<func> FROM PUBLIC, anon, authenticated;`
4. Service-role-only callers can keep working.
5. Coordinate with reso to formally close R-40 if relevant.

### 4.7 Analytics view missing `is_appstore_reviewer` filter

**Cause:** A new analytics view, recommendation model, or trust-score aggregate omitted the `WHERE is_appstore_reviewer(user_id) IS NOT TRUE` filter (CLAUDE.md §14 rule 4).

**Mitigation:**

1. Patch the view definition:
   ```sql
   CREATE OR REPLACE VIEW <view_name> AS
   SELECT ... FROM ...
   WHERE NOT EXISTS (...) -- existing filters
     AND is_appstore_reviewer(user_id) IS NOT TRUE; -- ADDED
   ```
2. Re-run the `check_appstore_reviewer.sh` healthcheck.
3. Document the addition in `docs/COMPLIANCE.md` if it's a load-bearing analytics seam.

---

## 5. Verification (after mitigation)

Mitigation is not complete until **all** of the following hold:

- [ ] §3.1 policy audit shows no `rowsecurity = false` on `public.*` tables
- [ ] §3.1 policy audit shows no zero-policy lockout on RLS-enabled tables
- [ ] `bash scripts/check_appstore_reviewer.sh` exits 0
- [ ] Reproduction of the regression no longer returns leaked rows
- [ ] `audit_logs` for the regression window have been preserved + indexed for incident retrospective
- [ ] No new Sentry alerts in the 30 minutes following the hotfix
- [ ] PagerDuty incident closed with a resolution comment linking back to the §3.2 failure class

If any verification fails, **do not close the incident** — escalate.

---

## 6. Communication (during the incident)

| Audience | Channel | When |
|:---|:---|:---|
| Engineering team | `#payments-incidents` Slack | At triage start, every 15 min during SEV-1 mitigation, at resolution |
| Founder + reso (incident commanders) | Direct message | Immediately on SEV-1 confirmation |
| Affected customers | Per Art. 34 GDPR — direct notification if exposure of "high risk to rights and freedoms" | Within 72h of awareness (post-mitigation; coordinated with DPA timing) |
| **Dutch DPA (Autoriteit Persoonsgegevens)** | Per **GDPR Art. 33** — within 72h of awareness | **MANDATORY for confirmed cross-tenant data exposure**. Coordinated with reso (GDPR sign-off authority). |
| Supabase support | Dashboard → Support | If RLS engine itself is suspected (extremely rare) |
| Status page (if public) | DeelMarkt status page | SEV-1 only, generic wording (no exposure detail) |

**GDPR Art. 33 timing:** the 72h clock starts at AWARENESS, not at exposure. Document the awareness timestamp. If unsure whether notification is required, **default to notify** — under-notification is the bigger legal risk.

**Legal hold:** preserve all `audit_logs` and `pg_stat_statements` from the regression window. Do not delete or rotate them until the incident retrospective lands.

---

## 7. Post-incident (within 5 business days)

- File a retrospective in `docs/audits/` named `INCIDENT-rls-<YYYY-MM-DD>.md` covering: timeline, awareness moment, regression window duration, exact data exposed (counts only, no PII), users affected, mitigation steps, GDPR notification timeline (DPA + users), lessons learned, action items
- Action items become GitHub issues with owners
- Update this runbook if the failure class was new
- Open a CI guard issue if the regression could have been caught at PR time (e.g. add a new policy-audit check to `appstore-reviewer-healthcheck.yml`)
- File an ADR if the incident exposes a structural pattern flaw

---

## 8. Escalation contacts

| Role | Who | Channel |
|:---|:---|:---|
| Primary owner (DB) | reso (`@MuBi2334`) | Slack DM, PagerDuty primary |
| Backup owner (consumers + healthchecks) | belengaz (`@mahmutkaya`) | Slack DM, PagerDuty secondary |
| Incident commander (SEV-1) | founder + reso jointly | Reserved for cross-tenant exposure or DPA-notification scenarios |
| Supabase support | Dashboard → Support | For RLS engine bugs only |
| Dutch DPA | [autoriteitpersoonsgegevens.nl](https://www.autoriteitpersoonsgegevens.nl/) | Art. 33 notification within 72h |
| External counsel | (per contract; founder coordinates) | For DPA notification language review |

---

## 9. Related runbooks (siblings under B-68)

- [`RUNBOOK-mollie-webhook-failure.md`](RUNBOOK-mollie-webhook-failure.md) — webhook DLQ; cross-references this runbook for SECURITY DEFINER concerns
- [`RUNBOOK-redis-outage.md`](RUNBOOK-redis-outage.md) — Redis outage (closed B-68 2/5)
- `RUNBOOK-cert-pinning-rotation.md` — cert rotation procedure (B-68 4/5, pending)
- `RUNBOOK-app-store-rejection.md` — App Store rejection response (B-68 5/5, pending)
- [`RUNBOOK-appstore-reviewer.md`](RUNBOOK-appstore-reviewer.md) — §14 fixture (cross-referenced in §4.4)

---

## 10. References

- CLAUDE.md §9 (Supabase Rules — RLS), §14 (App Store reviewer fixture)
- `docs/ARCHITECTURE.md` §Security
- `docs/COMPLIANCE.md` §RLS
- Migrations directory: `supabase/migrations/`
- Healthcheck: `scripts/check_appstore_reviewer.sh`
- Tier-1 retrospective: `docs/audits/2026-04-25-tier1-retrospective.md` §B-68 + §R-40
- Supabase RLS docs: [supabase.com/docs/guides/auth/row-level-security](https://supabase.com/docs/guides/auth/row-level-security)
- GDPR Art. 32 (security of processing): [gdpr-info.eu/art-32-gdpr](https://gdpr-info.eu/art-32-gdpr/)
- GDPR Art. 33 (breach notification to DPA): [gdpr-info.eu/art-33-gdpr](https://gdpr-info.eu/art-33-gdpr/)
- GDPR Art. 34 (breach notification to data subject): [gdpr-info.eu/art-34-gdpr](https://gdpr-info.eu/art-34-gdpr/)
