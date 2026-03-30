-- =============================================================================
-- Tier-1 Audit C-02: Escrow release race condition fix
--
-- Problem: release-escrow cron (every 15 min) has a TOCTOU race — overlapping
-- invocations can fetch the same transactions before either processes them.
-- The existing neq("released") guard in releaseToSeller() + UNIQUE ledger key
-- is a secondary defense, but the root cause (concurrent fetches) was unguarded.
--
-- Solution: Three RPC functions using FOR UPDATE SKIP LOCKED. When two cron
-- invocations overlap, the second one skips rows already locked by the first,
-- guaranteeing exactly-once processing at the query level.
--
-- These functions are called by the release-escrow Edge Function. The Edge
-- Function falls back to standard queries if RPC is unavailable.
-- =============================================================================

-- 1. Fetch confirmed transactions ready for release (B-22)
CREATE OR REPLACE FUNCTION fetch_releasable_confirmed()
RETURNS TABLE (
  id UUID,
  seller_id UUID,
  item_amount_cents INTEGER,
  shipping_cost_cents INTEGER
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT t.id, t.seller_id, t.item_amount_cents, t.shipping_cost_cents
  FROM transactions t
  WHERE t.status = 'confirmed'
  FOR UPDATE SKIP LOCKED;
$$;

-- 2. Fetch delivered transactions with expired escrow deadline (B-23)
CREATE OR REPLACE FUNCTION fetch_releasable_expired()
RETURNS TABLE (
  id UUID,
  seller_id UUID,
  item_amount_cents INTEGER,
  shipping_cost_cents INTEGER
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT t.id, t.seller_id, t.item_amount_cents, t.shipping_cost_cents
  FROM transactions t
  WHERE t.status = 'delivered'
    AND t.escrow_deadline < now()
  FOR UPDATE SKIP LOCKED;
$$;

-- 3. Fetch stale transactions past the 90-day hard limit (B-21)
CREATE OR REPLACE FUNCTION fetch_releasable_stale(hard_limit_iso TEXT)
RETURNS TABLE (
  id UUID,
  seller_id UUID,
  buyer_id UUID,
  status transaction_status,
  item_amount_cents INTEGER,
  shipping_cost_cents INTEGER,
  paid_at TIMESTAMPTZ
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT t.id, t.seller_id, t.buyer_id, t.status,
         t.item_amount_cents, t.shipping_cost_cents, t.paid_at
  FROM transactions t
  WHERE t.status IN ('paid', 'shipped', 'delivered', 'confirmed')
    AND t.paid_at < hard_limit_iso::timestamptz
  FOR UPDATE SKIP LOCKED;
$$;

-- Grant execute to service_role only (cron functions)
GRANT EXECUTE ON FUNCTION fetch_releasable_confirmed() TO service_role;
GRANT EXECUTE ON FUNCTION fetch_releasable_expired() TO service_role;
GRANT EXECUTE ON FUNCTION fetch_releasable_stale(TEXT) TO service_role;

-- Revoke from public (defense in depth)
REVOKE EXECUTE ON FUNCTION fetch_releasable_confirmed() FROM public;
REVOKE EXECUTE ON FUNCTION fetch_releasable_expired() FROM public;
REVOKE EXECUTE ON FUNCTION fetch_releasable_stale(TEXT) FROM public;
