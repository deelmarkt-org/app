-- R-33: Schedule daily seller response time calculation.
-- Calls the seller-response-time Edge Function every day at 02:00 UTC.
--
-- The function computes the median first-response time (in minutes) for each
-- active seller and writes it back to user_profiles.response_time_minutes.
-- The column already exists (added in phase_a migration B-39).
--
-- Runs at 02:00 UTC — after any end-of-day message activity, before the
-- daily-reconciliation cron at 06:00 and gdpr-cleanup-auth at 03:30.
--
-- Reference: docs/epics/E04-messaging.md §Seller Response Time

CREATE EXTENSION IF NOT EXISTS pg_cron;

DO $$
BEGIN
  PERFORM cron.unschedule('seller-response-time');
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;

SELECT cron.schedule(
  'seller-response-time',
  '0 2 * * *',
  $$
  SELECT net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/seller-response-time',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  );
  $$
);
