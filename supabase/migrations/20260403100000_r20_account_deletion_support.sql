-- R-20: Account deletion support tables
-- GDPR right-to-erasure with 30-day soft-delete grace period
-- Reference: docs/COMPLIANCE.md, docs/epics/E02-user-auth-kyc.md

-- ── notification_preferences ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notification_preferences (
  id                UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id           UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  messages          BOOLEAN NOT NULL DEFAULT true,
  offers            BOOLEAN NOT NULL DEFAULT true,
  shipping_updates  BOOLEAN NOT NULL DEFAULT true,
  marketing         BOOLEAN NOT NULL DEFAULT false,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

-- H-5: Use (SELECT auth.uid()) for per-query evaluation, not per-row
CREATE POLICY notification_preferences_own ON notification_preferences
  FOR ALL USING ((SELECT auth.uid()) = user_id);

-- M-1: updated_at trigger
CREATE TRIGGER set_notification_preferences_updated_at
  BEFORE UPDATE ON notification_preferences
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── user_addresses ─────────────────────────────────────────────────────
-- C-3: No UNIQUE constraint in table def — use COALESCE index instead
CREATE TABLE IF NOT EXISTS user_addresses (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  postcode        TEXT NOT NULL,
  house_number    TEXT NOT NULL,
  addition        TEXT,
  street          TEXT NOT NULL,
  city            TEXT NOT NULL,
  latitude        DOUBLE PRECISION,
  longitude       DOUBLE PRECISION,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- COALESCE index handles NULL addition correctly
CREATE UNIQUE INDEX idx_user_addresses_unique
  ON user_addresses(user_id, postcode, house_number, COALESCE(addition, ''));

ALTER TABLE user_addresses ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_addresses_own ON user_addresses
  FOR ALL USING ((SELECT auth.uid()) = user_id);

CREATE TRIGGER set_user_addresses_updated_at
  BEFORE UPDATE ON user_addresses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── gdpr_deletion_queue ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS gdpr_deletion_queue (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id         UUID NOT NULL,
  requested_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  delete_after    TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '30 days'),
  status          TEXT NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending', 'completed', 'cancelled', 'failed')),
  completed_at    TIMESTAMPTZ,
  error_message   TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE gdpr_deletion_queue ENABLE ROW LEVEL SECURITY;

CREATE POLICY gdpr_queue_service_only ON gdpr_deletion_queue
  FOR ALL USING (false);

CREATE UNIQUE INDEX idx_gdpr_queue_pending_user
  ON gdpr_deletion_queue(user_id)
  WHERE status = 'pending';

-- ── audit_logs ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS audit_logs (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     UUID,
  action      TEXT NOT NULL,
  metadata    JSONB DEFAULT '{}',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY audit_logs_service_only ON audit_logs
  FOR ALL USING (false);

-- ── Soft-delete columns ────────────────────────────────────────────────
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE listings ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- H-4: Allow NULL seller_id for anonymized deleted sellers (cron sets to NULL)
ALTER TABLE listings ALTER COLUMN seller_id DROP NOT NULL;

-- ── RLS policy updates (H-5: use SELECT auth.uid()) ───────────────────
DROP POLICY IF EXISTS user_profiles_select ON user_profiles;
CREATE POLICY user_profiles_select ON user_profiles
  FOR SELECT USING (deleted_at IS NULL OR (SELECT auth.uid()) = id);

DROP POLICY IF EXISTS listings_select ON listings;
CREATE POLICY listings_select ON listings
  FOR SELECT USING (
    (deleted_at IS NULL AND is_active = true AND is_sold = false)
    OR (SELECT auth.uid()) = seller_id
  );

-- ── H-2: Update view to filter soft-deleted listings ───────────────────
CREATE OR REPLACE VIEW listings_with_favourites AS
SELECT
  l.*,
  up.display_name AS seller_name,
  up.avatar_url AS seller_avatar_url,
  up.average_rating AS seller_rating,
  up.kyc_level AS seller_kyc_level,
  CASE
    WHEN (SELECT auth.uid()) IS NULL THEN false
    ELSE EXISTS(
      SELECT 1 FROM favourites f
      WHERE f.listing_id = l.id AND f.user_id = (SELECT auth.uid())
    )
  END AS is_favourited
FROM listings l
LEFT JOIN user_profiles up ON up.id = l.seller_id
WHERE l.deleted_at IS NULL;

GRANT SELECT ON listings_with_favourites TO authenticated, anon;

-- ── H-3: Update nearby_listings to filter soft-deleted ─────────────────
CREATE OR REPLACE FUNCTION nearby_listings(
  user_lat DOUBLE PRECISION,
  user_lon DOUBLE PRECISION,
  radius_km DOUBLE PRECISION DEFAULT 25.0,
  max_results INTEGER DEFAULT 50
)
RETURNS TABLE (listing_id UUID, distance_km DOUBLE PRECISION)
LANGUAGE sql STABLE
AS $$
  SELECT sub.listing_id, sub.distance_km
  FROM (
    SELECT l.id AS listing_id,
           haversine_km(user_lat, user_lon, l.latitude, l.longitude) AS distance_km
    FROM listings l
    WHERE l.is_active = true
      AND l.deleted_at IS NULL
      AND l.latitude BETWEEN (user_lat - radius_km / 111.0)
                         AND (user_lat + radius_km / 111.0)
      AND l.longitude BETWEEN (user_lon - radius_km / (111.0 * cos(radians(user_lat))))
                          AND (user_lon + radius_km / (111.0 * cos(radians(user_lat))))
  ) sub
  WHERE sub.distance_km <= radius_km
  ORDER BY sub.distance_km
  LIMIT max_results;
$$;

-- ── Atomic soft-delete RPC ─────────────────────────────────────────────
-- C-1: Verify caller matches target user
-- C-2: Hardened search_path, restricted to authenticated role
CREATE OR REPLACE FUNCTION soft_delete_account(
  p_user_id UUID,
  p_email_hash TEXT,
  p_ip TEXT DEFAULT 'unknown',
  p_user_agent TEXT DEFAULT 'unknown'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
BEGIN
  -- C-1: Caller must be the target user
  IF (SELECT auth.uid()) IS NULL OR (SELECT auth.uid()) != p_user_id THEN
    RAISE EXCEPTION 'Forbidden: caller does not match target user';
  END IF;

  -- M-2: Guard against already-deleted accounts
  IF EXISTS (SELECT 1 FROM user_profiles WHERE id = p_user_id AND deleted_at IS NOT NULL) THEN
    RAISE EXCEPTION 'Account already scheduled for deletion';
  END IF;

  -- Anonymize profile PII
  UPDATE user_profiles
  SET display_name = 'Verwijderd account',
      avatar_url = NULL,
      location = NULL,
      deleted_at = now(),
      updated_at = now()
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User profile not found';
  END IF;

  -- Soft-delete listings
  UPDATE listings SET deleted_at = now()
  WHERE seller_id = p_user_id AND deleted_at IS NULL;

  -- Delete PII tables
  DELETE FROM user_addresses WHERE user_id = p_user_id;
  DELETE FROM notification_preferences WHERE user_id = p_user_id;
  DELETE FROM favourites WHERE user_id = p_user_id;

  -- Queue hard-delete (MUST succeed — GDPR compliance)
  INSERT INTO gdpr_deletion_queue (user_id, status)
  VALUES (p_user_id, 'pending');

  -- Audit log
  INSERT INTO audit_logs (user_id, action, metadata)
  VALUES (p_user_id, 'account_deletion_requested', jsonb_build_object(
    'email_hash', p_email_hash,
    'ip', p_ip,
    'user_agent', p_user_agent
  ));
END;
$$;

-- C-2: Restrict RPC to authenticated users only
REVOKE ALL ON FUNCTION soft_delete_account(UUID, TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION soft_delete_account(UUID, TEXT, TEXT, TEXT) TO authenticated;

-- ── Indexes ────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_gdpr_queue_pending
  ON gdpr_deletion_queue(status, delete_after)
  WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_audit_logs_user
  ON audit_logs(user_id, created_at);

CREATE INDEX IF NOT EXISTS idx_user_profiles_deleted
  ON user_profiles(deleted_at) WHERE deleted_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_listings_deleted
  ON listings(deleted_at) WHERE deleted_at IS NOT NULL;
