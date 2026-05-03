-- ──────────────────────────────────────────────────────────────────────────
-- Issue #271 — notify_new_message: pull service-role key from Supabase Vault
--
-- Original (20260409100000_r34_device_tokens_and_push_trigger.sql) read the
-- service-role JWT via `current_setting('app.settings.service_role_key')`.
-- Two problems with that:
--
--   1. The single-arg form raises `42704: unrecognized configuration
--      parameter` if the GUC isn't set, so any INSERT INTO messages errored
--      out completely whenever the runtime missed the setting. Discovered
--      during the 2026-05-01 backlog clean-up — saved by zero traffic so
--      far (issue #271).
--   2. CLAUDE.md §9: "All API keys in Supabase Vault — never in env vars
--      or source code." `current_setting` of an `ALTER DATABASE`-stored GUC
--      keeps the JWT in `pg_db_role_setting`, readable by any role with
--      privileged access. Vault encrypts at rest with libsodium and only
--      decrypts on read for authorized roles.
--
-- This migration:
--
--   • Refactors the trigger to read the JWT from `vault.decrypted_secrets`
--     by name (`send_push_notification_service_role_key`).
--   • Reads the project URL from `app.settings.supabase_url` using the
--     two-arg `current_setting(name, missing_ok=true)` so a missing GUC
--     returns NULL instead of raising. URL is not a secret; storing it as
--     a DB-level GUC is fine (`ALTER DATABASE postgres SET …`).
--   • Becomes a graceful no-op (RAISE NOTICE) when either is missing.
--     Future Tuesday-without-push beats Tuesday-with-broken-INSERTS.
--
-- Operator setup (one-time per environment, not in this migration):
--   See docs/runbooks/RUNBOOK-push-notifications.md §2 for the post-merge
--   provisioning. Two steps:
--
--     1. ALTER DATABASE postgres SET app.settings.supabase_url
--          = 'https://<project-ref>.supabase.co';
--     2. SELECT vault.create_secret(
--          '<service_role_jwt>',
--          'send_push_notification_service_role_key',
--          'Service-role JWT consumed by public.notify_new_message
--           trigger to invoke /functions/v1/send-push-notification.'
--        );
--
-- Rollback: `_rollback/20260502120001_notify_new_message_use_vault_down.sql`
-- restores the original definition. No data migration involved.
-- ──────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.notify_new_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_url    TEXT;
  v_key    TEXT;
  payload  JSONB;
BEGIN
  -- Two-arg current_setting(name, missing_ok=true) returns NULL when the
  -- GUC isn't configured — does NOT raise. NULLIF strips the empty-string
  -- result that some PG installs return for never-set GUCs.
  v_url := NULLIF(current_setting('app.settings.supabase_url', true), '');

  -- Vault secret lookup. SECURITY DEFINER + postgres-owned function has
  -- SELECT on vault.decrypted_secrets by default. If the secret name is
  -- ever changed, update the operator runbook in the same PR.
  -- ORDER BY created_at DESC + LIMIT 1: vault.secrets has no UNIQUE
  -- constraint on (name), so a botched rotation that calls
  -- vault.create_secret() twice (instead of update_secret) would leave
  -- two rows. Without the ORDER BY, Postgres picks an arbitrary row and
  -- could silently return the rotated-out (revoked) JWT. Most-recent
  -- wins is the only sane interpretation here.
  SELECT decrypted_secret INTO v_key
  FROM vault.decrypted_secrets
  WHERE name = 'send_push_notification_service_role_key'
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_url IS NULL OR v_key IS NULL OR v_key = '' THEN
    -- Graceful no-op: missing config must not break message INSERTs. The
    -- NOTICE shows up in pg logs / Supabase observability so the gap is
    -- visible without breaking any caller. Re-running operator setup
    -- restores push notifications without any code redeploy.
    RAISE NOTICE
      'notify_new_message: app.settings.supabase_url or vault secret '
      'send_push_notification_service_role_key not configured — push skipped '
      '(see RUNBOOK-push-notifications.md §2 / issue #271). url_set=%, key_set=%.',
      v_url IS NOT NULL,
      v_key IS NOT NULL AND v_key <> '';
    RETURN NEW;
  END IF;

  payload := jsonb_build_object(
    'message_id', NEW.id,
    'conversation_id', NEW.conversation_id,
    'sender_id', NEW.sender_id,
    'text', LEFT(NEW.text, 200),
    'type', NEW.type::TEXT
  );

  PERFORM net.http_post(
    -- rtrim strips an optional trailing slash on the configured URL so
    -- `https://ref.supabase.co/` and `https://ref.supabase.co` both
    -- produce a clean single-slash path. Defensive against double-slash
    -- normalization quirks in upstream proxies.
    url := rtrim(v_url, '/') || '/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || v_key,
      'Content-Type', 'application/json'
    ),
    body := payload
  );

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.notify_new_message() IS
  'Trigger function (AFTER INSERT on messages) that fans a new message out '
  'via /functions/v1/send-push-notification. Reads the project URL from the '
  'app.settings.supabase_url GUC and the service-role JWT from vault. Issue '
  '#271 / migration 20260502120000.';
