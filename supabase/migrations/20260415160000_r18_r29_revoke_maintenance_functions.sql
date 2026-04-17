-- R-18 / R-29 hardening: revoke PostgREST RPC access on maintenance functions.
--
-- expire_stale_idin_sessions() and delete_processed_outbox_events() are
-- SECURITY DEFINER maintenance jobs intended to be executed exclusively by
-- the pg_cron background worker.  Without explicit REVOKE, they remain
-- callable over PostgREST RPC by any authenticated (or anon) user, enabling
-- denial-of-service vectors:
--
--   • SELECT public.expire_stale_idin_sessions()
--       — forcibly expires other users' pending iDIN sessions.
--
--   • SELECT public.delete_processed_outbox_events(0)
--       — deletes every processed row in search_outbox immediately,
--         bypassing the 7-day retention window.
--
-- Matches the established convention for service-role-only functions in
-- this codebase (e.g. gdpr_hard_delete_expired, get_overdue_dsa_reports,
-- flag_message_scam).

REVOKE ALL ON FUNCTION public.expire_stale_idin_sessions() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.expire_stale_idin_sessions() FROM anon;
REVOKE ALL ON FUNCTION public.expire_stale_idin_sessions() FROM authenticated;

REVOKE ALL ON FUNCTION public.delete_processed_outbox_events(INT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.delete_processed_outbox_events(INT) FROM anon;
REVOKE ALL ON FUNCTION public.delete_processed_outbox_events(INT) FROM authenticated;
