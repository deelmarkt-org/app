-- R-20: Account deletion support tables
-- GDPR right-to-erasure with 30-day soft-delete grace period
-- Reference: docs/COMPLIANCE.md, docs/epics/E02-user-auth-kyc.md

-- ── notification_preferences ───────────────────────────────────────────
-- One row per user (upsert pattern). CASCADE on user deletion.
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
-- Multiple per user. Composite unique on (user_id, postcode, house_number, addition).
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
-- Tracks account deletion requests for 30-day grace period.
-- Service-role only — users cannot query or modify directly.
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

-- No user-facing policies — service_role only
CREATE POLICY gdpr_queue_service_only ON gdpr_deletion_queue
  FOR ALL USING (false);

-- ── audit_logs ─────────────────────────────────────────────────────────
-- Append-only log for GDPR compliance. Retained 7 years (Dutch law).
-- Service-role only — no user reads/writes.
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
-- NULL = active, timestamp = soft-deleted. RLS hides deleted profiles.
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- Update RLS to hide deleted profiles from public reads
DROP POLICY IF EXISTS user_profiles_read ON user_profiles;
CREATE POLICY user_profiles_read ON user_profiles
  FOR SELECT USING (deleted_at IS NULL OR auth.uid() = id);

-- ── Soft-delete on listings ────────────────────────────────────────────
-- When user is soft-deleted, hide their listings from public
ALTER TABLE listings ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

DROP POLICY IF EXISTS listings_read ON listings;
CREATE POLICY listings_read ON listings
  FOR SELECT USING (deleted_at IS NULL);

-- ── Indexes ────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_gdpr_queue_pending
  ON gdpr_deletion_queue(status, delete_after)
  WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_audit_logs_user
  ON audit_logs(user_id, created_at);

CREATE INDEX IF NOT EXISTS idx_user_profiles_deleted
  ON user_profiles(deleted_at)
  WHERE deleted_at IS NOT NULL;
