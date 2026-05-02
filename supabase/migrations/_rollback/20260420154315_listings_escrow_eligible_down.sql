-- ──────────────────────────────────────────────────────────────────────────
-- Paired rollback for 20260420154314_listings_escrow_eligible.sql
--
-- Additive migration — rollback drops all objects in reverse dependency
-- order. No data loss: `listings.escrow_eligible` and
-- `categories.escrow_eligible` are server-computed trust signals; any app
-- surface reading them falls back to `false` via the DTO fail-closed path
-- once the columns disappear (ADR-023 §Rollback).
--
-- Apply only when rolling GH-59 / ADR-023 back end-to-end; the Unleash flag
-- `listings_escrow_badge` should be flipped OFF first (seconds-level kill)
-- to hide all badges before this runs.
--
-- NOT auto-applied — commit path is manual via `supabase db push` against
-- the target environment. Present in git as of GH-59 PR-B so on-call does
-- not have to craft it by hand at 3 AM.
-- ──────────────────────────────────────────────────────────────────────────

-- 1. Drop cascade triggers first so the primary trigger stops being invoked
--    transitively during DROP.
DROP TRIGGER IF EXISTS trg_categories_escrow_cascade ON categories;
DROP FUNCTION IF EXISTS trg_categories_cascade_escrow();

DROP TRIGGER IF EXISTS trg_user_profiles_kyc_cascade ON user_profiles;
DROP FUNCTION IF EXISTS trg_user_profiles_cascade_escrow();

-- 2. Drop the primary trigger + its function.
DROP TRIGGER IF EXISTS trg_listings_escrow_eligible ON listings;
DROP FUNCTION IF EXISTS trg_listings_recompute_escrow();

-- 3. Drop the shared helper function.
DROP FUNCTION IF EXISTS compute_escrow_eligible_for(
  UUID, BOOLEAN, BOOLEAN, INT, INT, UUID
);

-- 4. Drop the partial index.
DROP INDEX IF EXISTS idx_listings_escrow_eligible;

-- 5. Drop the columns. listings before categories because nothing on
--    categories references listings.
ALTER TABLE listings DROP COLUMN IF EXISTS escrow_eligible;
ALTER TABLE categories DROP COLUMN IF EXISTS escrow_eligible;
