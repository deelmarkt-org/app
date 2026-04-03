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

CREATE POLICY notification_preferences_own ON notification_preferences
  FOR ALL USING (auth.uid() = user_id);

-- ── user_addresses ─────────────────────────────────────────────────────
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
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, postcode, house_number, addition)
);

ALTER TABLE user_addresses ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_addresses_own ON user_addresses
  FOR ALL USING (auth.uid() = user_id);

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

-- Prevent duplicate pending deletions for same user (TOCTOU race fix)
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

-- ── Soft-delete column on user_profiles ────────────────────────────────
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- Replace existing SELECT policy to filter soft-deleted profiles
-- Original policy: user_profiles_select FOR SELECT USING (true)
DROP POLICY IF EXISTS user_profiles_select ON user_profiles;
CREATE POLICY user_profiles_select ON user_profiles
  FOR SELECT USING (deleted_at IS NULL OR auth.uid() = id);

-- ── Soft-delete on listings ────────────────────────────────────────────
ALTER TABLE listings ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- Replace existing SELECT policy to filter soft-deleted listings
-- Original policy: listings_select FOR SELECT USING ((is_active AND NOT is_sold) OR auth.uid() = seller_id)
DROP POLICY IF EXISTS listings_select ON listings;
CREATE POLICY listings_select ON listings
  FOR SELECT USING (
    (deleted_at IS NULL AND is_active = true AND is_sold = false)
    OR auth.uid() = seller_id
  );

-- ── Atomic soft-delete RPC (called by Edge Function) ───────────────────
-- All-or-nothing: if any step fails, the entire transaction rolls back.
-- This prevents partial deletion leaving inconsistent state (C-02 audit).
CREATE OR REPLACE FUNCTION soft_delete_account(
  p_user_id UUID,
  p_email_hash TEXT,
  p_ip TEXT DEFAULT 'unknown',
  p_user_agent TEXT DEFAULT 'unknown'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
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

-- Fix: UNIQUE constraint with COALESCE for nullable addition
DROP INDEX IF EXISTS user_addresses_user_id_postcode_house_number_addition_key;
CREATE UNIQUE INDEX idx_user_addresses_unique
  ON user_addresses(user_id, postcode, house_number, COALESCE(addition, ''));

-- ── Indexes ────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_gdpr_queue_pending
  ON gdpr_deletion_queue(status, delete_after)
  WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_audit_logs_user
  ON audit_logs(user_id, created_at);

CREATE INDEX IF NOT EXISTS idx_user_profiles_deleted
  ON user_profiles(deleted_at)
  WHERE deleted_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_listings_deleted
  ON listings(deleted_at)
  WHERE deleted_at IS NOT NULL;
