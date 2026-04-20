-- ──────────────────────────────────────────────────────────────────────────
-- GH-59 / ADR-023 — Backend-authoritative escrow eligibility
--
-- Adds a `escrow_eligible` boolean on `listings`, computed server-side by
-- trigger from the listing's status + price + quality score + the seller's
-- KYC level + the category's own eligibility flag. The Dart DTO reads this
-- column with a fail-closed default (false), so a misrendered badge is
-- impossible as long as the trigger is intact.
--
-- Dispute-count predicate (ADR-023 §Decision rule 2e) is deferred because
-- the `disputes` table ships in E03 Phase 2 — see TODO below.
--
-- Cascades:
--   * INSERT / UPDATE on listings       → recompute THAT row (BEFORE trigger)
--   * UPDATE of kyc_level on profile    → recompute ALL seller's listings
--   * UPDATE of categories.escrow_eligible → recompute ALL listings in
--                                           that category
--
-- Rollback: pair with `<ts>_listings_escrow_eligible_down.sql` which
-- drops the triggers, function, and column (additive migration — safe).
-- ──────────────────────────────────────────────────────────────────────────

-- 1. Prerequisite column on categories (D-1) — ADR-023 §Decision rule 2f.
--    Defaults to TRUE so no category is excluded until product defines the
--    excluded list; individual categories can later be switched off via
--    UPDATE and the cascade trigger will flip dependent listings in one
--    statement.
ALTER TABLE categories
  ADD COLUMN IF NOT EXISTS escrow_eligible BOOLEAN NOT NULL DEFAULT true;

COMMENT ON COLUMN categories.escrow_eligible IS
  'Whether listings in this category may be escrow-eligible. Default true '
  'for MVP; tighten per-category via follow-up migration once product '
  'defines excluded categories (services, digital goods). ADR-023.';

-- 2. The new column on listings. Fail-safe default = false so rows added
--    before the trigger fires never render a badge.
ALTER TABLE listings
  ADD COLUMN IF NOT EXISTS escrow_eligible BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN listings.escrow_eligible IS
  'Server-computed escrow eligibility. Set by trg_listings_escrow_eligible '
  'on every INSERT/UPDATE. Client-read-only — NEVER derive client-side. '
  'ADR-023.';

-- 3. Shared computation function. Takes a listing's inputs + the seller id
--    + the category id and returns the eligibility boolean.
--
--    Declared VOLATILE (not STABLE) so that per-row invocations inside the
--    cascade UPDATEs below always re-read the current kyc_level and
--    category.escrow_eligible. A STABLE function would let the planner cache
--    the first row's read and reuse it for every subsequent row — fine for a
--    single-row INSERT trigger, but unsafe in the AFTER UPDATE cascades where
--    the underlying row that changed (user_profiles / categories) is being
--    applied to many listings in one statement. See COMMENT ON FUNCTION below.
--
-- TODO(GH-59/E03 Phase 2): Re-add the dispute-count predicate once the
-- `disputes` table ships. Target rule from ADR-023 §Decision rule 2e:
-- COUNT(disputes WHERE seller_id = X AND status = 'active'
--       AND created_at > now() - 90 days) <= 2.
-- Tracking: https://github.com/deelmarkt-org/app/issues/59
CREATE OR REPLACE FUNCTION compute_escrow_eligible_for(
  p_seller_id      UUID,
  p_is_active      BOOLEAN,
  p_is_sold        BOOLEAN,
  p_price_cents    INT,
  p_quality_score  INT,
  p_category_id    UUID
) RETURNS BOOLEAN
LANGUAGE plpgsql VOLATILE AS $$
DECLARE
  v_kyc_level         TEXT;
  v_category_eligible BOOLEAN;
BEGIN
  -- Reads user_profiles + categories; both tables have public-read RLS
  -- (20260329161637 policies user_profiles_select + categories_select use
  -- USING (true)), so no SECURITY DEFINER is needed today. If those
  -- policies are ever tightened, mark this function SECURITY DEFINER
  -- owned by a role that retains SELECT on both tables — otherwise the
  -- COALESCE chain will silently flip every badge off.
  SELECT kyc_level::TEXT INTO v_kyc_level
    FROM user_profiles WHERE id = p_seller_id;

  SELECT escrow_eligible INTO v_category_eligible
    FROM categories WHERE id = p_category_id;

  RETURN (
    COALESCE(p_is_active, false)                 AND
    COALESCE(p_is_sold, false)             = false AND
    COALESCE(p_price_cents, 0)            >= 5000 AND
    COALESCE(p_quality_score, 0)          >= 50   AND
    COALESCE(v_kyc_level, 'level0')       <> 'level0' AND
    COALESCE(v_category_eligible, false)
  );
END;
$$;

COMMENT ON FUNCTION compute_escrow_eligible_for IS
  'Pure read helper — shared by trg_listings_escrow_eligible, the cascade '
  'triggers, and the backfill UPDATE. Declared VOLATILE so per-row trigger '
  'evaluations inside multi-row UPDATE statements (cascades) always re-read '
  'user_profiles.kyc_level and categories.escrow_eligible instead of caching '
  'the first invocation''s result.';

-- 4. Primary trigger: recompute on every listing INSERT/UPDATE.
CREATE OR REPLACE FUNCTION trg_listings_recompute_escrow()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.escrow_eligible := compute_escrow_eligible_for(
    NEW.seller_id,
    NEW.is_active,
    NEW.is_sold,
    NEW.price_cents,
    NEW.quality_score,
    NEW.category_id
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_listings_escrow_eligible ON listings;
CREATE TRIGGER trg_listings_escrow_eligible
  BEFORE INSERT OR UPDATE ON listings
  FOR EACH ROW EXECUTE FUNCTION trg_listings_recompute_escrow();

-- 5. Cascade on user_profiles.kyc_level change (D-4). When a seller gains
--    or loses a KYC level, every one of their listings is recomputed in a
--    single UPDATE — the primary trigger above fires for each row so the
--    computation stays consistent.
CREATE OR REPLACE FUNCTION trg_user_profiles_cascade_escrow()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF OLD.kyc_level IS DISTINCT FROM NEW.kyc_level THEN
    -- Only rewrite listings whose computed eligibility actually changes.
    -- The IS DISTINCT FROM predicate avoids write amplification and spurious
    -- Realtime fan-out on rows whose result did not move.
    UPDATE listings SET updated_at = now()
    WHERE seller_id = NEW.id
      AND escrow_eligible IS DISTINCT FROM compute_escrow_eligible_for(
        seller_id, is_active, is_sold, price_cents, quality_score, category_id
      );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_user_profiles_kyc_cascade ON user_profiles;
CREATE TRIGGER trg_user_profiles_kyc_cascade
  AFTER UPDATE OF kyc_level ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION trg_user_profiles_cascade_escrow();

-- 6. Cascade on categories.escrow_eligible change. Same pattern as kyc —
--    a single UPDATE touches every listing in the category so the primary
--    trigger recomputes per row.
CREATE OR REPLACE FUNCTION trg_categories_cascade_escrow()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF OLD.escrow_eligible IS DISTINCT FROM NEW.escrow_eligible THEN
    UPDATE listings SET updated_at = now()
    WHERE category_id = NEW.id
      AND escrow_eligible IS DISTINCT FROM compute_escrow_eligible_for(
        seller_id, is_active, is_sold, price_cents, quality_score, category_id
      );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_categories_escrow_cascade ON categories;
CREATE TRIGGER trg_categories_escrow_cascade
  AFTER UPDATE OF escrow_eligible ON categories
  FOR EACH ROW EXECUTE FUNCTION trg_categories_cascade_escrow();

-- 7. One-shot backfill via the helper (D-6). Single pass, no write
--    amplification on rows that already match the computed value.
UPDATE listings SET
  escrow_eligible = compute_escrow_eligible_for(
    seller_id,
    is_active,
    is_sold,
    price_cents,
    quality_score,
    category_id
  )
WHERE escrow_eligible IS DISTINCT FROM compute_escrow_eligible_for(
  seller_id,
  is_active,
  is_sold,
  price_cents,
  quality_score,
  category_id
);

-- 8. Partial index so future "filter by escrow" search queries are fast
--    without paying storage cost on the 90%+ rows that are ineligible.
CREATE INDEX IF NOT EXISTS idx_listings_escrow_eligible
  ON listings (escrow_eligible)
  WHERE escrow_eligible = true;

-- 9. RLS — escrow_eligible is a public trust signal (ADR-023 §Decision +
--    F-8 audit finding). No row-level change needed: the existing SELECT
--    policy already exposes listing columns to anon + authenticated when
--    the row passes the active/unsold/not-deleted gate.
