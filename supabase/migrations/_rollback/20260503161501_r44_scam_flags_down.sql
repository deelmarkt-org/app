-- ──────────────────────────────────────────────────────────────────────────
-- Paired rollback for 20260503161500_r44_scam_flags.sql
--
-- Drops the R-44 DSA transparency surface in reverse dependency order.
-- Safe to apply: the only consumer (SuspensionGateScreen wiring, #259)
-- conditionally renders on `statement != null`, so a missing RPC
-- gracefully degrades to "no DSA panel" rather than erroring.
-- ──────────────────────────────────────────────────────────────────────────

DROP FUNCTION IF EXISTS public.get_active_scam_flag(UUID);

DROP POLICY IF EXISTS scam_flags_deny_writes ON public.scam_flags;
DROP POLICY IF EXISTS scam_flags_own_select  ON public.scam_flags;

DROP TRIGGER IF EXISTS scam_flags_updated_at ON public.scam_flags;

DROP INDEX IF EXISTS public.idx_scam_flags_user_active_recent;

DROP TABLE IF EXISTS public.scam_flags;
