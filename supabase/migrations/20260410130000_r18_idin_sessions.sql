-- R-18: iDIN identity verification sessions + KYC upgrade RPC
--
-- iDIN is the Dutch bank-based identity verification scheme used to
-- gate KYC level1 → level2 for listings >= €500 (E02 epic §4.2).
--
-- Table: idin_sessions — audit trail for every verification attempt.
--   • One pending session per user enforced via partial unique index.
--   • Completed/failed sessions are kept for the 5-year GDPR audit window.
--
-- RPCs:
--   • create_idin_session()     — SECURITY INVOKER (user-facing, rate-limited EF)
--   • upgrade_kyc_to_level2()   — SECURITY DEFINER (service-role only, called by EF)
--   • complete_idin_session()   — SECURITY DEFINER (service-role only, webhook/callback)
--   • expire_stale_idin_sessions() — SECURITY DEFINER (cron, marks sessions expired after 1h)

-- ---------------------------------------------------------------------------
-- Session status enum
-- ---------------------------------------------------------------------------

CREATE TYPE idin_session_status AS ENUM (
  'pending',    -- initiated, awaiting user bank redirect completion
  'completed',  -- bank confirmed identity, kyc_level upgraded to level2
  'failed',     -- bank returned error or user cancelled
  'expired'     -- no completion within 1 hour
);

-- ---------------------------------------------------------------------------
-- idin_sessions table
-- ---------------------------------------------------------------------------

CREATE TABLE idin_sessions (
  id              UUID                 PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID                 NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  session_token   TEXT                 NOT NULL UNIQUE,
  status          idin_session_status  NOT NULL DEFAULT 'pending',
  initiated_at    TIMESTAMPTZ          NOT NULL DEFAULT now(),
  expires_at      TIMESTAMPTZ          NOT NULL DEFAULT (now() + INTERVAL '1 hour'),
  completed_at    TIMESTAMPTZ,
  failure_reason  TEXT,

  CONSTRAINT idin_session_completed_requires_timestamp
    CHECK (status != 'completed' OR completed_at IS NOT NULL),
  CONSTRAINT idin_session_failure_requires_reason
    CHECK (status NOT IN ('failed', 'expired') OR failure_reason IS NOT NULL)
);

-- One active (pending) session per user — prevents concurrent initiations.
CREATE UNIQUE INDEX idin_sessions_one_pending_per_user
  ON idin_sessions (user_id)
  WHERE status = 'pending';

CREATE INDEX idx_idin_sessions_user_id     ON idin_sessions (user_id);
CREATE INDEX idx_idin_sessions_token       ON idin_sessions (session_token);
CREATE INDEX idx_idin_sessions_expires_at  ON idin_sessions (expires_at) WHERE status = 'pending';

-- Automatically update expires_at / completed_at via updated_at trigger if needed
-- (no updated_at column here — idin_sessions are append-only audit records)

-- ---------------------------------------------------------------------------
-- RLS — users can read their own sessions; service role manages all
-- ---------------------------------------------------------------------------

ALTER TABLE idin_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY idin_sessions_select_own
  ON idin_sessions
  FOR SELECT
  USING (auth.uid() = user_id);

-- No INSERT/UPDATE/DELETE policy for regular users — only service role
-- (via SECURITY DEFINER RPCs) writes to this table.

-- ---------------------------------------------------------------------------
-- create_idin_session — called by initiate-idin EF (service role)
--
-- Inserts a new pending session and returns the session_token.
-- Raises if user already has a pending session.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION create_idin_session(
  p_user_id      UUID,
  p_session_token TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO idin_sessions (user_id, session_token)
  VALUES (p_user_id, p_session_token);
  -- Unique index on (user_id) WHERE status='pending' raises on conflict.
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'User already has a pending iDIN session'
      USING ERRCODE = 'P0001';
END;
$$;

-- ---------------------------------------------------------------------------
-- upgrade_kyc_to_level2 — called by initiate-idin EF (mock) or
-- complete_idin_session after successful bank callback.
--
-- Idempotent: no-op if already level2+.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION upgrade_kyc_to_level2(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE user_profiles
  SET
    kyc_level  = 'level2',
    updated_at = now()
  WHERE id = p_user_id
    AND kyc_level IN ('level0', 'level1');  -- idempotent: skip if already level2+
END;
$$;

-- ---------------------------------------------------------------------------
-- complete_idin_session — called by the iDIN bank callback webhook EF.
--
-- Marks the session completed and upgrades the user's KYC level atomically.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION complete_idin_session(p_session_token TEXT)
RETURNS UUID  -- returns user_id on success
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
BEGIN
  UPDATE idin_sessions
  SET
    status       = 'completed',
    completed_at = now()
  WHERE session_token = p_session_token
    AND status = 'pending'
    AND expires_at > now()
  RETURNING user_id INTO v_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'iDIN session not found, already processed, or expired'
      USING ERRCODE = 'P0002';
  END IF;

  PERFORM upgrade_kyc_to_level2(v_user_id);

  RETURN v_user_id;
END;
$$;

-- ---------------------------------------------------------------------------
-- expire_stale_idin_sessions — run by pg_cron daily to clean up.
--
-- Marks sessions that have passed their expiry as 'expired'.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION expire_stale_idin_sessions()
RETURNS INT  -- number of sessions expired
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INT;
BEGIN
  UPDATE idin_sessions
  SET
    status         = 'expired',
    failure_reason = 'Session expired after 1 hour without completion'
  WHERE status = 'pending'
    AND expires_at <= now();

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

-- Schedule daily cleanup (pg_cron — requires pg_cron extension enabled in Supabase)
-- SELECT cron.schedule('expire-idin-sessions', '0 * * * *', 'SELECT expire_stale_idin_sessions()');
-- Note: uncomment and run once via Supabase SQL editor after enabling pg_cron.
