-- Audit fixes: new columns + pg_cron scheduling
-- Fixes: H3 (alerted_at), H4 (cron), M1 (last_attempted_at)

-- =============================================================================
-- 1. Add last_attempted_at and alerted_at to mollie_webhook_events (M1, H3)
-- =============================================================================
ALTER TABLE mollie_webhook_events
  ADD COLUMN last_attempted_at TIMESTAMPTZ,
  ADD COLUMN alerted_at TIMESTAMPTZ;

-- =============================================================================
-- 2. Schedule daily-reconciliation (daily at 06:00 UTC) and webhook-dlq
--    (every 5 minutes) via pg_cron (H4)
-- =============================================================================

-- Enable pg_cron extension if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Grant usage to postgres role
GRANT USAGE ON SCHEMA cron TO postgres;

-- Daily reconciliation — runs at 06:00 UTC every day
SELECT cron.schedule(
  'daily-reconciliation',
  '0 6 * * *',
  $$
  SELECT net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/daily-reconciliation',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  );
  $$
);

-- Webhook DLQ processor — runs every 5 minutes
SELECT cron.schedule(
  'webhook-dlq',
  '*/5 * * * *',
  $$
  SELECT net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/webhook-dlq',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  );
  $$
);

-- =============================================================================
-- 3. Store mollie_webhook_secret placeholder in Vault (H5)
--    The actual secret must be updated from Mollie dashboard
-- =============================================================================
SELECT vault.create_secret(
  'REPLACE_WITH_MOLLIE_WEBHOOK_SECRET',
  'mollie_webhook_secret',
  'Mollie webhook signing secret — update from Mollie dashboard'
);
