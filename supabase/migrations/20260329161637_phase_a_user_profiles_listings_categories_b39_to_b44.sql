-- Phase A: Core tables for listings, users, categories, favourites
-- Tasks: B-39 (user_profiles), B-40 (listings), B-41 (categories), B-42 (favourites)
-- Tasks: B-43 (FTS), B-44 (haversine distance)
-- Reference: docs/SPRINT-PLAN.md §Sprint 5-8, docs/epics/E01-listing-management.md

-- =============================================================================
-- 1. B-39: User profiles table
-- =============================================================================
-- Extends auth.users with marketplace-specific fields.
-- auth.users handles email/phone/password; this table handles display info.

CREATE TYPE kyc_level AS ENUM ('level0', 'level1', 'level2');

CREATE TABLE user_profiles (
  id                      UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name            TEXT NOT NULL CHECK (char_length(display_name) BETWEEN 2 AND 50),
  avatar_url              TEXT,
  location                TEXT,
  kyc_level               kyc_level NOT NULL DEFAULT 'level0',
  badges                  TEXT[] NOT NULL DEFAULT '{}',
  average_rating          NUMERIC(2,1) CHECK (average_rating >= 0 AND average_rating <= 5),
  review_count            INTEGER NOT NULL DEFAULT 0 CHECK (review_count >= 0),
  response_time_minutes   INTEGER CHECK (response_time_minutes >= 0),
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_user_profiles_display_name ON user_profiles (display_name);
CREATE INDEX idx_user_profiles_kyc_level ON user_profiles (kyc_level);

-- Auto-update updated_at (uses update_updated_at() from transactions migration)
CREATE TRIGGER set_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Anyone can read profiles (public marketplace)
CREATE POLICY user_profiles_select ON user_profiles
  FOR SELECT USING (true);

-- Users can only insert/update their own profile
CREATE POLICY user_profiles_insert ON user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY user_profiles_update ON user_profiles
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- No deletes — account deletion handled by GDPR Edge Function (R-20)
CREATE POLICY user_profiles_no_delete ON user_profiles
  FOR DELETE USING (false);

-- =============================================================================
-- 2. B-41: Categories table (before listings, for FK)
-- =============================================================================

CREATE TABLE categories (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name        TEXT NOT NULL,
  name_nl     TEXT NOT NULL,
  icon        TEXT NOT NULL,
  parent_id   UUID REFERENCES categories(id) ON DELETE CASCADE,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_categories_parent ON categories (parent_id);

-- RLS: categories are public read, admin write (service_role)
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY categories_select ON categories
  FOR SELECT USING (true);

-- Seed L1 categories (8 per design system)
INSERT INTO categories (id, name, name_nl, icon, parent_id, sort_order) VALUES
  ('c1000000-0000-0000-0000-000000000001', 'Electronics', 'Elektronica', 'device-mobile', NULL, 1),
  ('c1000000-0000-0000-0000-000000000002', 'Fashion', 'Kleding', 'tshirt', NULL, 2),
  ('c1000000-0000-0000-0000-000000000003', 'Home & Garden', 'Huis & Tuin', 'house', NULL, 3),
  ('c1000000-0000-0000-0000-000000000004', 'Sports', 'Sport', 'bicycle', NULL, 4),
  ('c1000000-0000-0000-0000-000000000005', 'Books & Media', 'Boeken & Media', 'book-open', NULL, 5),
  ('c1000000-0000-0000-0000-000000000006', 'Vehicles', 'Voertuigen', 'car', NULL, 6),
  ('c1000000-0000-0000-0000-000000000007', 'Kids', 'Kinderen', 'baby', NULL, 7),
  ('c1000000-0000-0000-0000-000000000008', 'Other', 'Overig', 'dots-three', NULL, 8);

-- Seed L2 subcategories (initial set)
INSERT INTO categories (name, name_nl, icon, parent_id, sort_order) VALUES
  ('Phones', 'Telefoons', 'device-mobile', 'c1000000-0000-0000-0000-000000000001', 1),
  ('Laptops', 'Laptops', 'laptop', 'c1000000-0000-0000-0000-000000000001', 2),
  ('Gaming', 'Gaming', 'game-controller', 'c1000000-0000-0000-0000-000000000001', 3),
  ('Audio', 'Audio', 'headphones', 'c1000000-0000-0000-0000-000000000001', 4),
  ('Men', 'Heren', 'tshirt', 'c1000000-0000-0000-0000-000000000002', 1),
  ('Women', 'Dames', 'dress', 'c1000000-0000-0000-0000-000000000002', 2),
  ('Shoes', 'Schoenen', 'sneaker', 'c1000000-0000-0000-0000-000000000002', 3),
  ('Furniture', 'Meubels', 'armchair', 'c1000000-0000-0000-0000-000000000003', 1),
  ('Kitchen', 'Keuken', 'cooking-pot', 'c1000000-0000-0000-0000-000000000003', 2),
  ('Garden', 'Tuin', 'plant', 'c1000000-0000-0000-0000-000000000003', 3),
  ('Fitness', 'Fitness', 'barbell', 'c1000000-0000-0000-0000-000000000004', 1),
  ('Cycling', 'Fietsen', 'bicycle', 'c1000000-0000-0000-0000-000000000004', 2),
  ('Outdoor', 'Outdoor', 'tent', 'c1000000-0000-0000-0000-000000000004', 3);

-- =============================================================================
-- 3. B-40: Listings table
-- =============================================================================

CREATE TYPE listing_condition AS ENUM ('new_with_tags', 'new_without_tags', 'like_new', 'good', 'fair', 'poor');

CREATE TABLE listings (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  seller_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title           TEXT NOT NULL CHECK (char_length(title) BETWEEN 3 AND 100),
  description     TEXT NOT NULL CHECK (char_length(description) BETWEEN 10 AND 2000),
  price_cents     INTEGER NOT NULL CHECK (price_cents > 0 AND price_cents <= 100000000),
  condition       listing_condition NOT NULL,
  category_id     UUID NOT NULL REFERENCES categories(id),
  image_urls      TEXT[] NOT NULL DEFAULT '{}' CHECK (array_length(image_urls, 1) <= 12),
  location        TEXT,
  latitude        DOUBLE PRECISION,
  longitude       DOUBLE PRECISION,
  quality_score   INTEGER CHECK (quality_score >= 0 AND quality_score <= 100),
  is_sold         BOOLEAN NOT NULL DEFAULT false,
  is_active       BOOLEAN NOT NULL DEFAULT true,
  view_count      INTEGER NOT NULL DEFAULT 0 CHECK (view_count >= 0),
  favourite_count INTEGER NOT NULL DEFAULT 0 CHECK (favourite_count >= 0),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- B-43: Full-text search vector (Dutch)
ALTER TABLE listings ADD COLUMN search_vector tsvector
  GENERATED ALWAYS AS (
    setweight(to_tsvector('dutch', coalesce(title, '')), 'A') ||
    setweight(to_tsvector('dutch', coalesce(description, '')), 'B')
  ) STORED;

-- Indexes
CREATE INDEX idx_listings_seller ON listings (seller_id);
CREATE INDEX idx_listings_category ON listings (category_id);
CREATE INDEX idx_listings_active ON listings (is_active, is_sold) WHERE is_active = true AND is_sold = false;
CREATE INDEX idx_listings_created ON listings (created_at DESC);
CREATE INDEX idx_listings_price ON listings (price_cents);
CREATE INDEX idx_listings_search ON listings USING GIN (search_vector);
CREATE INDEX idx_listings_location ON listings (latitude, longitude) WHERE latitude IS NOT NULL;

-- Auto-update updated_at (uses update_updated_at() from transactions migration)
CREATE TRIGGER set_listings_updated_at
  BEFORE UPDATE ON listings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- RLS
ALTER TABLE listings ENABLE ROW LEVEL SECURITY;

-- Anyone can read active listings
CREATE POLICY listings_select ON listings
  FOR SELECT USING (is_active = true OR auth.uid() = seller_id);

-- Only authenticated users can create listings
CREATE POLICY listings_insert ON listings
  FOR INSERT WITH CHECK (auth.uid() = seller_id);

-- Sellers can update their own listings
CREATE POLICY listings_update ON listings
  FOR UPDATE USING (auth.uid() = seller_id)
  WITH CHECK (auth.uid() = seller_id);

-- Sellers can soft-delete (set is_active = false) but not hard delete
CREATE POLICY listings_no_delete ON listings
  FOR DELETE USING (false);

-- =============================================================================
-- 4. Add FK from transactions to listings (was TODO in B-17)
-- =============================================================================

ALTER TABLE transactions
  ADD CONSTRAINT fk_transactions_listing
  FOREIGN KEY (listing_id) REFERENCES listings(id) ON DELETE RESTRICT;

-- =============================================================================
-- 5. B-42: Favourites table
-- =============================================================================

CREATE TABLE favourites (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  listing_id  UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, listing_id)
);

CREATE INDEX idx_favourites_user ON favourites (user_id);
CREATE INDEX idx_favourites_listing ON favourites (listing_id);

-- RLS
ALTER TABLE favourites ENABLE ROW LEVEL SECURITY;

-- Users can see their own favourites
CREATE POLICY favourites_select ON favourites
  FOR SELECT USING (auth.uid() = user_id);

-- Users can add/remove their own favourites
CREATE POLICY favourites_insert ON favourites
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY favourites_delete ON favourites
  FOR DELETE USING (auth.uid() = user_id);

-- Update favourite_count on listings when favourites change
CREATE OR REPLACE FUNCTION update_favourite_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE listings SET favourite_count = favourite_count + 1 WHERE id = NEW.listing_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE listings SET favourite_count = favourite_count - 1 WHERE id = OLD.listing_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_update_favourite_count
  AFTER INSERT OR DELETE ON favourites
  FOR EACH ROW
  EXECUTE FUNCTION update_favourite_count();

-- =============================================================================
-- 6. B-44: Haversine distance function
-- =============================================================================
-- Returns distance in km between two lat/lng pairs.
-- Used for "nearby listings" queries. PostGIS not needed for MVP.

CREATE OR REPLACE FUNCTION haversine_km(
  lat1 DOUBLE PRECISION,
  lon1 DOUBLE PRECISION,
  lat2 DOUBLE PRECISION,
  lon2 DOUBLE PRECISION
) RETURNS DOUBLE PRECISION AS $$
DECLARE
  r CONSTANT DOUBLE PRECISION := 6371.0;
  dlat DOUBLE PRECISION;
  dlon DOUBLE PRECISION;
  a DOUBLE PRECISION;
BEGIN
  dlat := radians(lat2 - lat1);
  dlon := radians(lon2 - lon1);
  a := sin(dlat / 2) ^ 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon / 2) ^ 2;
  RETURN r * 2 * asin(sqrt(a));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Convenience: search listings within radius
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
BEGIN
  RETURN QUERY
  SELECT
    l.id AS listing_id,
    haversine_km(user_lat, user_lon, l.latitude, l.longitude) AS distance_km
  FROM listings l
  WHERE l.is_active = true
    AND l.is_sold = false
    AND l.latitude IS NOT NULL
    AND l.longitude IS NOT NULL
    AND haversine_km(user_lat, user_lon, l.latitude, l.longitude) <= radius_km
  ORDER BY distance_km ASC
  LIMIT max_results;
END;
$$ LANGUAGE plpgsql STABLE;
