-- Phase A PR #27 review fixes — consolidated into audit_fixes migration
-- The RLS policy fix and nearby_listings optimization are already applied
-- in 20260329192715_phase_a_audit_fixes.sql. This migration is kept as a
-- no-op to preserve migration history ordering.

-- Note: count(*) in favourite_count trigger is accurate but slow at scale (>100K rows).
-- Revisit with pg_advisory_lock or deferred batch updates when needed.
-- For MVP volume (<10K favourites) this is fine.
