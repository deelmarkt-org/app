-- Phase A PR #27 review fixes — bounding box optimization + RLS sold filter
-- Addresses: Gemini HIGH (sold items visible, full scan), emredursun M3 (count comment)

-- =============================================================================
-- 1. RLS: Sold items should not be publicly visible
-- =============================================================================

DROP POLICY IF EXISTS listings_select ON listings;
CREATE POLICY listings_select ON listings
  FOR SELECT USING ((is_active = true AND is_sold = false) OR auth.uid() = seller_id);

-- =============================================================================
-- 2. Bounding box optimization for nearby_listings
-- =============================================================================
-- Pre-filters using B-tree index on (latitude, longitude) before computing
-- expensive haversine. ~100x faster than full table scan at scale.

CREATE OR REPLACE FUNCTION nearby_listings(
  user_lat DOUBLE PRECISION,
  user_lon DOUBLE PRECISION,
  radius_km DOUBLE PRECISION DEFAULT 25.0,
  max_results INTEGER DEFAULT 50
)
RETURNS TABLE (
  listing_id UUID,
  distance_km DOUBLE PRECISION
) AS $$
DECLARE
  -- 1 degree latitude ≈ 111km. Longitude varies by cos(lat).
  lat_delta DOUBLE PRECISION := radius_km / 111.0;
  lon_delta DOUBLE PRECISION := radius_km / (111.0 * cos(radians(user_lat)));
BEGIN
  RETURN QUERY
  SELECT sub.listing_id, sub.distance_km
  FROM (
    SELECT
      l.id AS listing_id,
      haversine_km(user_lat, user_lon, l.latitude, l.longitude) AS distance_km
    FROM listings l
    WHERE l.is_active = true
      AND l.is_sold = false
      AND l.latitude IS NOT NULL
      AND l.longitude IS NOT NULL
      -- Bounding box pre-filter (uses B-tree index on latitude, longitude)
      AND l.latitude BETWEEN (user_lat - lat_delta) AND (user_lat + lat_delta)
      AND l.longitude BETWEEN (user_lon - lon_delta) AND (user_lon + lon_delta)
  ) sub
  WHERE sub.distance_km <= radius_km
  ORDER BY sub.distance_km ASC
  LIMIT max_results;
END;
$$ LANGUAGE plpgsql STABLE;

-- =============================================================================
-- 3. Add scale comment to favourite_count trigger (emredursun M3)
-- =============================================================================
-- Note: count(*) is accurate but slow at scale (>100K rows).
-- Revisit with pg_advisory_lock or deferred batch updates when needed.
-- For MVP volume (<10K favourites) this is fine.
