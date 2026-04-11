-- R-38: DSA notice-and-action reporting table + 24-hour SLA tracking
-- Implements E06-trust-moderation.md §DSA Transparency Module.
--
-- Key design decisions:
-- 1. report INSERT is exposed via submit_dsa_report() RPC (SECURITY INVOKER).
--    All moderator UPDATEs (status, resolution) go via service_role.
-- 2. target_id is a plain UUID (no FK). Reports can target listings, messages,
--    profiles, or reviews — a polymorphic FK is impractical; application logic
--    enforces that the referenced row exists before submission.
-- 3. sla_deadline = reported_at + 24h, set server-side in the RPC.
--    The get_overdue_dsa_reports() function is the canonical SLA query for the
--    admin dashboard; never rely on client-side clock for SLA status.
-- 4. One report per (reporter, target) pair per day to throttle abuse.
--    Additional submissions within 24h return the existing row (idempotent RPC).
-- 5. Reviewed_by ON DELETE SET NULL — preserves audit trail on moderator offboarding.
--
-- Reference: docs/epics/E06-trust-moderation.md §DSA Transparency Module
-- Reference: docs/SPRINT-PLAN.md R-38

-- =============================================================================
-- 1. ENUMs
-- =============================================================================

CREATE TYPE dsa_target_t AS ENUM (
  'listing',
  'message',
  'profile',
  'review'
);

CREATE TYPE dsa_category_t AS ENUM (
  'illegal_content',    -- CSAM, terrorism, hate speech (DSA Art. 3(h))
  'prohibited_item',    -- Platform-policy prohibited goods
  'counterfeit',        -- Fake branded goods
  'fraud',              -- Scam listings / fake transactions
  'privacy_violation',  -- Personal data shared without consent
  'other'
);

CREATE TYPE dsa_status_t AS ENUM (
  'pending',       -- Newly filed, not yet assigned
  'under_review',  -- Moderator assigned and reviewing
  'actioned',      -- Content removed / user sanctioned
  'rejected'       -- Report found to be unfounded
);

-- =============================================================================
-- 2. dsa_reports table
-- =============================================================================

CREATE TABLE dsa_reports (
  id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Reporter (nullable on CASCADE delete so history survives account deletion)
  reporter_id     UUID          REFERENCES auth.users(id) ON DELETE SET NULL,

  -- What is being reported
  target_type     dsa_target_t  NOT NULL,
  target_id       UUID          NOT NULL,

  -- DSA report category (Art. 16 notice-and-action)
  category        dsa_category_t NOT NULL,

  -- Plain-language description (required — vague reports are rejected)
  description     TEXT          NOT NULL CHECK (length(trim(description)) >= 10),

  -- Timestamps
  reported_at     TIMESTAMPTZ   NOT NULL DEFAULT now(),

  -- SLA deadline: 24 hours from reported_at (enforced by platform policy + DSA)
  sla_deadline    TIMESTAMPTZ   NOT NULL,

  -- Lifecycle status
  status          dsa_status_t  NOT NULL DEFAULT 'pending',

  -- Resolution fields — updated by moderator via service_role
  reviewed_by     UUID          REFERENCES auth.users(id) ON DELETE SET NULL,
  reviewed_at     TIMESTAMPTZ,
  resolution_notes TEXT,

  updated_at      TIMESTAMPTZ,

  -- sla_deadline must be exactly 24h after reported_at
  CONSTRAINT dsa_sla_deadline_check
    CHECK (sla_deadline = reported_at + INTERVAL '24 hours'),

  -- Resolution requires a reviewer
  CONSTRAINT dsa_resolution_requires_reviewer
    CHECK (reviewed_at IS NULL OR reviewed_by IS NOT NULL),

  -- Unique per (reporter, target) per day — throttle abuse
  CONSTRAINT dsa_one_report_per_target_per_day
    UNIQUE NULLS NOT DISTINCT (reporter_id, target_id, target_type)
);

CREATE INDEX idx_dsa_reports_reporter ON dsa_reports (reporter_id, reported_at DESC);

-- SLA monitoring index: fast lookup for overdue pending/in-review reports
CREATE INDEX idx_dsa_reports_sla ON dsa_reports (sla_deadline, status)
  WHERE status IN ('pending', 'under_review');

-- =============================================================================
-- 3. updated_at trigger
-- =============================================================================
-- Reuses update_updated_at() defined in 20260321232641.

CREATE TRIGGER dsa_reports_updated_at
  BEFORE UPDATE ON dsa_reports
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =============================================================================
-- 4. RLS — dsa_reports
-- =============================================================================

ALTER TABLE dsa_reports ENABLE ROW LEVEL SECURITY;

-- Reporters can read their own reports (to show submission history + status).
CREATE POLICY dsa_reports_own_select ON dsa_reports
  FOR SELECT USING (reporter_id = auth.uid());

-- INSERT is handled by submit_dsa_report() RPC (SECURITY INVOKER).
-- All other mutations (UPDATE status, resolution) are service_role-only.

-- =============================================================================
-- 5. RPC: submit_dsa_report
-- =============================================================================
-- Authenticated users file a DSA notice-and-action report.
-- Idempotent: if the same (reporter, target_type, target_id) pair exists,
-- returns the existing row without inserting a duplicate (per the UNIQUE
-- constraint + ON CONFLICT DO NOTHING).
--
-- Sets sla_deadline = now() + 24h server-side.
-- Returns the inserted (or existing) report row.

CREATE OR REPLACE FUNCTION submit_dsa_report(
  p_target_type  dsa_target_t,
  p_target_id    UUID,
  p_category     dsa_category_t,
  p_description  TEXT
)
RETURNS SETOF dsa_reports
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
  v_user_id   UUID := auth.uid();
  v_now       TIMESTAMPTZ := now();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User must be authenticated to submit a DSA report';
  END IF;

  IF p_description IS NULL OR length(trim(p_description)) < 10 THEN
    RAISE EXCEPTION 'Report description must be at least 10 characters';
  END IF;

  -- Insert; silently ignore if the same (reporter, target) already reported.
  INSERT INTO public.dsa_reports (
    reporter_id,
    target_type,
    target_id,
    category,
    description,
    reported_at,
    sla_deadline
  )
  VALUES (
    v_user_id,
    p_target_type,
    p_target_id,
    p_category,
    p_description,
    v_now,
    v_now + INTERVAL '24 hours'
  )
  ON CONFLICT (reporter_id, target_id, target_type) DO NOTHING;

  RETURN QUERY
    SELECT * FROM public.dsa_reports
    WHERE reporter_id = v_user_id
      AND target_id   = p_target_id
      AND target_type = p_target_type
    ORDER BY reported_at DESC
    LIMIT 1;
END;
$$;

REVOKE ALL ON FUNCTION submit_dsa_report(dsa_target_t, UUID, dsa_category_t, TEXT) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION submit_dsa_report(dsa_target_t, UUID, dsa_category_t, TEXT) TO authenticated;

-- =============================================================================
-- 6. RPC: get_overdue_dsa_reports
-- =============================================================================
-- Returns all reports that have breached the 24-hour SLA and are still open.
-- Used by the admin moderation dashboard (Retool / service_role).
-- Not exposed to authenticated or anon roles.

CREATE OR REPLACE FUNCTION get_overdue_dsa_reports()
RETURNS SETOF dsa_reports
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT *
  FROM   public.dsa_reports
  WHERE  sla_deadline < now()
    AND  status IN ('pending', 'under_review')
  ORDER  BY sla_deadline ASC;
$$;

REVOKE ALL ON FUNCTION get_overdue_dsa_reports() FROM PUBLIC;
-- Intentionally not granted to authenticated — service_role only (admin panel).
