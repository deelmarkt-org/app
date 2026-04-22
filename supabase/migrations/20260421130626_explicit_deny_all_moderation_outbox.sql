-- ──────────────────────────────────────────────────────────────────────────
-- RLS: make the effective deny-all explicit for moderation_queue + search_outbox
--
-- Both tables have `ENABLE ROW LEVEL SECURITY` with zero policies —
-- which Postgres interprets as an implicit deny-all for non-superuser
-- roles (`authenticated`, `anon`). `service_role` bypasses RLS and
-- continues to read/write via the relevant Edge Functions + RPCs.
--
-- Architecture audit (closes issue #187):
--
-- moderation_queue
--   • Writer: `flag_message_scam` RPC, called by the scam-detection
--     Edge Function with service_role.
--     (See supabase/migrations/20260409120000_r35_... line 52 and
--      supabase/functions/scam-detection/index.ts line 14.)
--   • Reader: no Dart client code references the table. The admin
--     dashboard reads summary counts via admin_stats_entity, not raw
--     rows. If a future moderator panel needs direct client reads,
--     that will require a new migration with a role-gated policy —
--     explicitly NOT in scope here (closing-over behaviour is exactly
--     what was intended per the migration header comment).
--
-- search_outbox
--   • Writer: `notify_search_outbox` trigger, AFTER-INSERT/UPDATE on
--     `listings`, fires as the triggering role (effectively any
--     authenticated or service_role INSERT on listings).
--   • Reader: `process-search-outbox` Edge Function with service_role.
--   • Pure outbox pattern. No client access intended, ever.
--
-- The advisor flags RLS-on-no-policies because the intent is ambiguous
-- when reading the schema — you can't tell whether the author forgot
-- to add a policy or meant deny-all. Making the deny-all explicit
-- resolves that ambiguity without changing behaviour.
--
-- NOTE on the trigger INSERT path for search_outbox: the trigger runs
-- as the invoker by default. With RLS enabled and a deny-all policy,
-- authenticated listing writes would get rejected when the trigger
-- tried to insert. The existing migration handles this by declaring
-- `notify_search_outbox` as SECURITY DEFINER (see 20260411100000 line
-- 66) so the insert runs as the function owner (supabase_admin /
-- postgres), which bypasses RLS. Deny-all policies are therefore safe.
-- ──────────────────────────────────────────────────────────────────────────

-- moderation_queue — explicit deny-all for authenticated + anon.
CREATE POLICY moderation_queue_deny_all ON public.moderation_queue
  FOR ALL
  TO authenticated, anon
  USING (false)
  WITH CHECK (false);

COMMENT ON POLICY moderation_queue_deny_all ON public.moderation_queue IS
  'Deny-all for non-service roles. Writes go through flag_message_scam '
  'RPC (SECURITY DEFINER, service_role). If a moderator panel ever '
  'needs direct client reads, add a role-gated policy in a new migration.';

-- search_outbox — explicit deny-all for authenticated + anon.
CREATE POLICY search_outbox_deny_all ON public.search_outbox
  FOR ALL
  TO authenticated, anon
  USING (false)
  WITH CHECK (false);

COMMENT ON POLICY search_outbox_deny_all ON public.search_outbox IS
  'Deny-all for non-service roles. Trigger (SECURITY DEFINER) inserts; '
  'process-search-outbox Edge Function (service_role) reads/deletes. '
  'No client access intended — this table is an internal outbox.';
