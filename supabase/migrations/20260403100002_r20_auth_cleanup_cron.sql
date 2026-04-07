-- R-20 Stage 2: Schedule the gdpr-cleanup-auth Edge Function.
-- Runs daily at 03:30 UTC, 30 minutes after the SQL hard-delete cron
-- (20260403100001) so Stage 1 entries are visible to Stage 2 in the same day.
--
-- Two-stage erasure rationale: see 20260403100001_r20_hard_delete_cron.sql.

CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Idempotent re-schedule (unschedule is a no-op if the job doesn't exist —
-- wrap in a DO block so re-running the migration doesn't error).
DO $$
BEGIN
  PERFORM cron.unschedule('gdpr-cleanup-auth');
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;

SELECT cron.schedule(
  'gdpr-cleanup-auth',
  '30 3 * * *',
  $$
  SELECT net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/gdpr-cleanup-auth',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  );
  $$
);
