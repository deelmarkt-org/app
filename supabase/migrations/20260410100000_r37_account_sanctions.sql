-- R-37: Account sanctions + appeal/reinstatement flow
-- Implements warn/suspend/ban lifecycle from E06-trust-moderation.md §Account Suspension.
--
-- Key design decisions:
-- 1. Sanctions are service_role-only for INSERT/UPDATE. Users read their own via SELECT RLS.
-- 2. Appeal flow: user calls submit_appeal() RPC (SECURITY INVOKER, RLS enforced).
--    14-day window, one appeal per sanction, no counter-appeal after decision.
-- 3. get_active_sanction() RPC: returns latest non-expired suspension/ban.
--    Warnings never block access — informational only.
-- 4. Push notification on sanction INSERT: reuses R-34 pg_net + send-push-notification
--    Edge Function pattern. Edge Function selects FCM template by event type.
-- 5. Reinstatement: moderator sets appeal_decision = 'overturned' + resolved_at.
--    Listings are NOT deleted during suspension (RLS blocks new creation only).
-- 6. Fraudulent seller path: moderator sets type = 'ban'; downstream iDIN revocation
--    and Wwft flag are handled by admin panel (service_role direct UPDATE).
--
-- Reference: docs/epics/E06-trust-moderation.md §Account Suspension & Recovery
-- Reference: docs/SPRINT-PLAN.md R-37

-- =============================================================================
-- 1. ENUMs
-- =============================================================================

CREATE TYPE sanction_type     AS ENUM ('warning', 'suspension', 'ban');
CREATE TYPE appeal_decision_t AS ENUM ('upheld', 'overturned');

-- =============================================================================
-- 2. account_sanctions table
-- =============================================================================

CREATE TABLE account_sanctions (
  id          UUID              PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID              NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  type        sanction_type     NOT NULL,

  -- Plain-language reason required (E06: no vague "policy violation" allowed)
  reason      TEXT              NOT NULL CHECK (length(trim(reason)) > 0),

  -- NULL = permanent; set for temporary suspensions (7/14/30 days)
  expires_at  TIMESTAMPTZ,

  -- Moderator who issued the sanction.
  -- ON DELETE SET NULL: preserves the audit trail if a moderator account is removed.
  issued_by   UUID              REFERENCES auth.users(id) ON DELETE SET NULL,

  created_at  TIMESTAMPTZ       NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ,

  -- Appeal fields — populated by submit_appeal() RPC
  appealed_at TIMESTAMPTZ,
  appeal_body TEXT,

  -- Resolution fields — updated by moderator via service_role
  appeal_decision appeal_decision_t,
  resolved_at TIMESTAMPTZ,
  -- ON DELETE SET NULL: same rationale as issued_by.
  resolved_by UUID              REFERENCES auth.users(id) ON DELETE SET NULL,

  -- Bans are always permanent (no expires_at)
  CONSTRAINT sanctions_ban_no_expiry
    CHECK (type != 'ban' OR expires_at IS NULL),
  -- appeal_body required once appeal is submitted
  CONSTRAINT sanctions_appeal_body_required
    CHECK (appealed_at IS NULL OR (appeal_body IS NOT NULL AND length(trim(appeal_body)) > 0)),
  -- resolution requires a prior appeal
  CONSTRAINT sanctions_resolve_requires_appeal
    CHECK (resolved_at IS NULL OR appealed_at IS NOT NULL)
);

CREATE INDEX idx_account_sanctions_user    ON account_sanctions (user_id, created_at DESC);
CREATE INDEX idx_account_sanctions_active  ON account_sanctions (user_id, expires_at)
  WHERE type IN ('suspension', 'ban') AND resolved_at IS NULL;

-- =============================================================================
-- 3. updated_at trigger
-- =============================================================================
-- Tracks when a moderator updates the row (appeal decision, reinstatement).
-- Reuses update_updated_at() defined in 20260321232641.

CREATE TRIGGER account_sanctions_updated_at
  BEFORE UPDATE ON account_sanctions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =============================================================================
-- 4. RLS — account_sanctions
-- =============================================================================

ALTER TABLE account_sanctions ENABLE ROW LEVEL SECURITY;

-- Users can read their own sanctions (to show suspension screen + appeal form).
CREATE POLICY sanctions_own_select ON account_sanctions
  FOR SELECT USING (user_id = auth.uid());

-- All mutations (INSERT/UPDATE/DELETE) are service_role-only.
-- Moderator actions go via admin panel (service_role key).
-- User appeals go via submit_appeal() RPC (SECURITY INVOKER — UPDATE allowed by RPC).

-- =============================================================================
-- 5. RPC: get_active_sanction
-- =============================================================================
-- Returns the most recent active suspension or ban for a user, or empty set.
-- Warnings are excluded — they are informational only and never block access.
--
-- A sanction is "active" when ALL of:
--   - type IN ('suspension', 'ban')
--   - appeal_decision IS DISTINCT FROM 'overturned' (not lifted by appeal)
--   - expires_at IS NULL OR expires_at > now()           (not expired)
--
-- Called by the Flutter app on startup / auth state change to gate users.

CREATE OR REPLACE FUNCTION get_active_sanction(p_user_id UUID)
RETURNS SETOF account_sanctions
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT *
  FROM   public.account_sanctions
  WHERE  user_id = p_user_id
    AND  type IN ('suspension', 'ban')
    AND  (appeal_decision IS DISTINCT FROM 'overturned')
    AND  (expires_at IS NULL OR expires_at > now())
  ORDER  BY created_at DESC
  LIMIT  1;
$$;

REVOKE ALL ON FUNCTION get_active_sanction(UUID) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION get_active_sanction(UUID) TO authenticated, anon;

-- =============================================================================
-- 6. RPC: submit_appeal
-- =============================================================================
-- Allows a suspended/banned user to submit an appeal within 14 days.
-- Idempotent: a second call revises the appeal_body (user can edit before decision).
--
-- Enforced constraints:
--   - Caller must be the sanctioned user (SECURITY INVOKER + WHERE user_id = uid).
--   - Only suspension/ban can be appealed (warnings cannot).
--   - 14-day appeal window from created_at.
--   - Cannot appeal after a final decision (no counter-appeal).
--
-- Returns the updated sanction row.

CREATE OR REPLACE FUNCTION submit_appeal(
  p_sanction_id UUID,
  p_appeal_body TEXT
)
RETURNS SETOF account_sanctions
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_sanction public.account_sanctions;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User must be authenticated to submit an appeal';
  END IF;

  -- Validate body
  IF p_appeal_body IS NULL OR length(trim(p_appeal_body)) = 0 THEN
    RAISE EXCEPTION 'Appeal body must not be empty';
  END IF;

  -- Fetch and verify ownership
  SELECT * INTO v_sanction
  FROM   public.account_sanctions
  WHERE  id = p_sanction_id
    AND  user_id = v_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sanction not found or access denied';
  END IF;

  -- Warnings cannot be appealed
  IF v_sanction.type = 'warning' THEN
    RAISE EXCEPTION 'Warnings cannot be appealed';
  END IF;

  -- Enforce 14-day window
  IF v_sanction.created_at < now() - INTERVAL '14 days' THEN
    RAISE EXCEPTION 'Appeal window has closed (14 days from sanction date)';
  END IF;

  -- No counter-appeal after final decision
  IF v_sanction.appeal_decision IS NOT NULL THEN
    RAISE EXCEPTION 'A final decision has already been made — counter-appeal not permitted';
  END IF;

  -- Upsert: set body; stamp appealed_at only on first submission
  UPDATE public.account_sanctions
  SET    appeal_body = p_appeal_body,
         appealed_at = COALESCE(appealed_at, now())
  WHERE  id = p_sanction_id;

  RETURN QUERY
    SELECT * FROM public.account_sanctions WHERE id = p_sanction_id;
END;
$$;

REVOKE ALL ON FUNCTION submit_appeal(UUID, TEXT) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION submit_appeal(UUID, TEXT) TO authenticated;

-- =============================================================================
-- 7. Push notification trigger on new sanction
-- =============================================================================
-- On INSERT, fires an async HTTP call to the send-sanction-notification Edge
-- Function. That function resolves FCM tokens, builds a sanction-specific push
-- title/body, and skips notification_preferences (sanctions are mandatory legal
-- comms, not opt-out). Idempotency key: sanction_id.
--
-- Payload keys:
--   event       → 'account_sanctioned'
--   sanction_id → NEW.id (used as Redis idempotency key)
--   user_id     → sanctioned user
--   type        → 'warning' | 'suspension' | 'ban'
--   reason      → plain-language reason text
--   expires_at  → ISO timestamp or null

CREATE OR REPLACE FUNCTION notify_account_sanctioned()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  payload JSONB;
BEGIN
  payload := jsonb_build_object(
    'event',       'account_sanctioned',
    'sanction_id', NEW.id,
    'user_id',     NEW.user_id,
    'type',        NEW.type::TEXT,
    'reason',      NEW.reason,
    'expires_at',  NEW.expires_at
  );

  PERFORM net.http_post(
    url     := current_setting('app.settings.supabase_url')
               || '/functions/v1/send-sanction-notification',
    headers := jsonb_build_object(
      'Authorization', 'Bearer '
                       || current_setting('app.settings.service_role_key'),
      'Content-Type',  'application/json'
    ),
    body    := payload
  );

  RETURN NEW;
END;
$$;

CREATE TRIGGER account_sanctions_push_notify
  AFTER INSERT ON public.account_sanctions
  FOR EACH ROW EXECUTE FUNCTION notify_account_sanctioned();
