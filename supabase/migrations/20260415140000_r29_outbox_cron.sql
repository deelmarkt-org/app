-- R-29 ops: pg_cron schedule for search outbox cleanup.
--
-- The delete_processed_outbox_events() function (defined in
-- 20260411100000_r29_search_outbox.sql) deletes rows from search_outbox
-- that were already processed and are older than 7 days.  This prevents
-- unbounded table growth and index bloat on idx_search_outbox_unprocessed.
--
-- Runs daily at 03:00 UTC — same window as the GDPR hard-delete cron to
-- batch infrastructure maintenance together and avoid peak traffic hours.
--
-- Requires pg_cron extension (enabled by default on Supabase Pro).
-- Idempotent: unschedule-then-reschedule pattern prevents duplicate jobs.

CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Idempotent: remove any existing job with this name before re-creating.
SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname = 'delete-processed-outbox';

SELECT cron.schedule(
  'delete-processed-outbox',
  '0 3 * * *',  -- daily at 03:00 UTC
  $$SELECT public.delete_processed_outbox_events(7)$$
);
