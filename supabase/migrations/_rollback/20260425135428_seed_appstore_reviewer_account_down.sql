-- ──────────────────────────────────────────────────────────────────────────
-- GH #162 — App Store reviewer demo account seed (DOWN)
--
-- Reverses 20260425135427_seed_appstore_reviewer_account.sql. Removes the
-- seeded ancillary rows in dependency order, then drops the helper
-- function. Does NOT delete the auth.users rows — those are managed by
-- the runbook so an operator can rotate credentials without re-running
-- a migration. See docs/runbooks/RUNBOOK-appstore-reviewer.md §Revoke.
--
-- Idempotent: every DELETE / DROP uses IF EXISTS or a WHERE filter that
-- silently skips missing rows, so this can be applied against an
-- environment that never ran the up-migration without raising.
-- ──────────────────────────────────────────────────────────────────────────

DO $appstore_reviewer_unseed$
DECLARE
  v_seller_id   CONSTANT UUID := 'aa162162-0000-0000-0000-000000000001';
  v_buyer_id    CONSTANT UUID := 'aa162162-0000-0000-0000-000000000002';
  v_listing_id  CONSTANT UUID := 'aa162162-0000-0000-0000-000000000010';
  v_txn_id      CONSTANT UUID := 'aa162162-0000-0000-0000-000000000020';
  v_convo_id    CONSTANT UUID := 'aa162162-0000-0000-0000-000000000030';
BEGIN
  -- Order matters: messages → conversations → transactions → listings →
  -- profiles. ON DELETE CASCADE on most FKs would handle this, but being
  -- explicit makes the rollback auditable.
  DELETE FROM public.messages       WHERE conversation_id = v_convo_id;
  DELETE FROM public.conversations  WHERE id = v_convo_id;
  DELETE FROM public.transactions   WHERE id = v_txn_id;
  DELETE FROM public.listings       WHERE id = v_listing_id;
  DELETE FROM public.user_profiles  WHERE id IN (v_seller_id, v_buyer_id);
END
$appstore_reviewer_unseed$;

DROP FUNCTION IF EXISTS public.is_appstore_reviewer(UUID);
