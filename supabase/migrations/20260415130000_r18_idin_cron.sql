-- R-18 ops: pg_cron schedule for iDIN session expiry cleanup.
--
-- The expire_stale_idin_sessions() function (defined in
-- 20260410130000_r18_idin_sessions.sql) marks pending iDIN sessions as
-- 'expired' once their expires_at has passed.  Sessions are 1-hour TTL,
-- so an hourly cron at the top of the hour is sufficient.
--
-- Note: create_idin_session() already auto-expires stale sessions inline
-- on each new initiation attempt, so this cron is a belt-and-suspenders
-- cleanup — it ensures the table doesn't accumulate open 'pending' rows
-- if the user never retries after a timeout.
--
-- Requires pg_cron extension (enabled by default on Supabase Pro).
-- Idempotent: unschedule-then-reschedule pattern prevents duplicate jobs.

CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Idempotent: remove any existing job with this name before re-creating.
SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname = 'expire-idin-sessions';

SELECT cron.schedule(
  'expire-idin-sessions',
  '0 * * * *',  -- every hour at :00
  $$SELECT public.expire_stale_idin_sessions()$$
);
