# RUNBOOK — Push notification trigger configuration

> **Owner:** belengaz / reso (DB)
> **Closes:** issue #271
> **Last reviewed:** 2026-05-02

This runbook is the canonical procedure for configuring the
`public.notify_new_message()` trigger so it can invoke the
`send-push-notification` Edge Function on every new chat message.

The trigger is graceful — without configuration it logs a `NOTICE` and
returns; message INSERTs succeed regardless. With configuration, every
new message fans out to FCM via the Edge Function.

---

## 1. What the trigger needs

| Source | Name | Type | Why |
| :--- | :--- | :--- | :--- |
| GUC (DB-level setting) | `app.settings.supabase_url` | `TEXT` | Project URL prefix, e.g. `https://<ref>.supabase.co`. **Not a secret** — fine to live in `pg_db_role_setting`. |
| Vault secret | `send_push_notification_service_role_key` | `vault.secrets` | Service-role JWT used for the `Authorization: Bearer …` header on the inbound HTTP call. **Secret** — must live in Vault per CLAUDE.md §9. |

Both are read by [supabase/migrations/20260502120000_notify_new_message_use_vault.sql](../../supabase/migrations/20260502120000_notify_new_message_use_vault.sql).

---

## 2. One-time provisioning (per environment)

### 2a. Configure the project URL GUC

```bash
# From a psql session against the pooler (or via the Supabase SQL editor):
ALTER DATABASE postgres
  SET app.settings.supabase_url = 'https://<your-project-ref>.supabase.co';

-- Verify (new sessions only — existing sessions inherit the old value):
SELECT current_setting('app.settings.supabase_url', true);
```

### 2b. Insert the service-role JWT into Vault

> **CLAUDE.md §9 — never paste the JWT into chat or commit it.** The
> operator runs this from a local terminal with the secret pulled from
> 1Password (`Supabase service_role`).

```bash
# In your shell, NOT in chat:
SERVICE_ROLE_JWT=$(grep '^SUPABASE_SERVICE_ROLE_SECRET=' .env | cut -d= -f2-)
psql "$SUPABASE_DB_URL" <<SQL
SELECT vault.create_secret(
  '$SERVICE_ROLE_JWT',
  'send_push_notification_service_role_key',
  'Service-role JWT consumed by public.notify_new_message trigger to invoke /functions/v1/send-push-notification. Issue #271.'
);
SQL
```

### 2c. Verify the trigger is now wired

```sql
-- Both should return TRUE
SELECT current_setting('app.settings.supabase_url', true) IS NOT NULL AND current_setting('app.settings.supabase_url', true) <> '' AS url_set;
SELECT EXISTS (SELECT 1 FROM vault.decrypted_secrets WHERE name='send_push_notification_service_role_key') AS key_set;
```

### 2d. Smoke test (synthetic message INSERT)

> Run against a non-production environment first. The reviewer-fixture
> conversation `aa162162-…0030` is a safe target on prod because the
> seller (`…0001`) is the demo account — push fans out to whatever
> `device_tokens` the demo seller has registered. If the demo account
> has no devices registered, the EF logs a "no recipients" notice and
> exits cleanly.

```sql
DO $$
DECLARE v_id UUID := gen_random_uuid();
BEGIN
  INSERT INTO public.messages (id, conversation_id, sender_id, text, type, is_read, created_at)
  VALUES (
    v_id,
    'aa162162-0000-0000-0000-000000000030',
    'aa162162-0000-0000-0000-000000000001',
    '#271 push smoke test — ignore', 'text', false, now()
  );
  DELETE FROM public.messages WHERE id = v_id;  -- clean up
END $$;

-- Confirm an HTTP request was queued by pg_net (look for the most recent row):
SELECT id, status_code, error_msg, created
FROM net._http_response
ORDER BY created DESC
LIMIT 5;
```

A `status_code = 200` row appearing within ~5 seconds confirms the EF
was reached. Anything else (timeout, 401, 5xx) indicates a config or EF
bug — see §3 troubleshooting below.

---

## 3. Troubleshooting

| Symptom | Likely cause | Fix |
| :--- | :--- | :--- |
| `NOTICE: notify_new_message: … not configured — push skipped` | §2a or §2b not run, or run against the wrong DB | Re-run §2a / §2b against the correct project. New sessions only — restart pgbouncer connections. |
| `net._http_response.status_code = 401` | Service-role JWT in Vault is invalid or expired | Rotate the JWT (Supabase dashboard → Settings → API), then `SELECT vault.update_secret('send_push_notification_service_role_key', '<new_jwt>')`. |
| `error_msg LIKE '%Connection refused%'` | URL GUC points at a non-existent project ref or a stale environment | Re-run §2a with the correct project URL. |
| Trigger fires but no FCM push lands on device | EF reached but no device tokens for the recipient | Expected for unregistered devices. Check `public.device_tokens` for the recipient `user_id`. |

---

## 4. Rotation

When the service-role JWT is rotated (90-day cadence per Supabase
recommendation, or on staff change):

```sql
SELECT vault.update_secret(
  'send_push_notification_service_role_key',
  '<new_jwt>'
);
```

`vault.update_secret` re-encrypts the new value with the same secret
name, so the trigger sees the new key on its next call without any
function redeploy.

---

## 5. Reference

- Migration: [`supabase/migrations/20260502120000_notify_new_message_use_vault.sql`](../../supabase/migrations/20260502120000_notify_new_message_use_vault.sql)
- Rollback: [`supabase/migrations/_rollback/20260502120001_notify_new_message_use_vault_down.sql`](../../supabase/migrations/_rollback/20260502120001_notify_new_message_use_vault_down.sql)
- Edge Function: `supabase/functions/send-push-notification/`
- Issue: [#271](https://github.com/deelmarkt-org/app/issues/271)
