-- Phase A Round 3 fixes — KYC enum expansion, view NULL safety, category counts
-- Audit findings: C1 (kyc_level), C2 (auth.uid NULL), H2 (listingCount)

-- =============================================================================
-- C1: Expand kyc_level enum to include level3 and level4
-- =============================================================================
-- Dart UserEntity has 5 levels: level0-level4
-- DB only had 3 (level0-level2). Adding level3 (ID verified) and level4 (KVK business).

ALTER TYPE kyc_level ADD VALUE IF NOT EXISTS 'level3';
ALTER TYPE kyc_level ADD VALUE IF NOT EXISTS 'level4';

-- =============================================================================
-- C2: Fix listings_with_favourites view — explicit NULL check for auth.uid()
-- =============================================================================
-- Anonymous users have auth.uid() = NULL. SQL NULL comparisons are fragile.
-- Explicit check: only compute is_favourited when user is authenticated.

CREATE OR REPLACE VIEW listings_with_favourites AS
SELECT
  l.*,
  up.display_name AS seller_name,
  up.avatar_url AS seller_avatar_url,
  up.average_rating AS seller_rating,
  up.kyc_level AS seller_kyc_level,
  -- Anonymous users (auth.uid() IS NULL) always see false
  CASE
    WHEN auth.uid() IS NULL THEN false
    ELSE EXISTS(
      SELECT 1 FROM favourites f
      WHERE f.listing_id = l.id AND f.user_id = auth.uid()
    )
  END AS is_favourited
FROM listings l
LEFT JOIN user_profiles up ON up.id = l.seller_id;

-- =============================================================================
-- H2: Add listing_count to categories via trigger
-- =============================================================================
-- Denormalized count maintained by trigger on listings INSERT/UPDATE/DELETE.
-- Enables CategoryEntity.listingCount without expensive COUNT(*) queries.

ALTER TABLE categories ADD COLUMN listing_count INTEGER NOT NULL DEFAULT 0;

-- Function to update category listing count (incremental +1/-1 for performance)
CREATE OR REPLACE FUNCTION update_category_listing_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.is_active = true AND NEW.is_sold = false AND NEW.category_id IS NOT NULL THEN
      UPDATE categories SET listing_count = listing_count + 1 WHERE id = NEW.category_id;
    END IF;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.is_active = true AND OLD.is_sold = false AND OLD.category_id IS NOT NULL THEN
      UPDATE categories SET listing_count = GREATEST(listing_count - 1, 0) WHERE id = OLD.category_id;
    END IF;
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    -- Determine if old row was counted
    IF OLD.is_active = true AND OLD.is_sold = false AND OLD.category_id IS NOT NULL THEN
      -- Old row was active — decrement old category
      IF OLD.category_id IS DISTINCT FROM NEW.category_id
         OR NEW.is_active = false OR NEW.is_sold = true THEN
        UPDATE categories SET listing_count = GREATEST(listing_count - 1, 0) WHERE id = OLD.category_id;
      END IF;
    END IF;
    -- Determine if new row should be counted
    IF NEW.is_active = true AND NEW.is_sold = false AND NEW.category_id IS NOT NULL THEN
      -- New row is active — increment new category
      IF NEW.category_id IS DISTINCT FROM OLD.category_id
         OR OLD.is_active = false OR OLD.is_sold = true THEN
        UPDATE categories SET listing_count = listing_count + 1 WHERE id = NEW.category_id;
      END IF;
    END IF;
    RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_update_category_listing_count
  AFTER INSERT OR UPDATE OR DELETE ON listings
  FOR EACH ROW
  EXECUTE FUNCTION update_category_listing_count();
