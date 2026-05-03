-- ──────────────────────────────────────────────────────────────────────────
-- R-44 — DSA Art. 17 Statement of Reasons backend (table + RPC)
--
-- Surfaces automated scam-detection decisions to the affected user via
-- `SuspensionGateScreen`. The UI side shipped in PR #256
-- (`ScamFlagStatementOfReasons` widget); the wiring depends on this
-- migration landing first (issue #259).
--
-- Scope of THIS migration:
--   * `scam_flags` table — one row per automated flag the moderation
--     pipeline issues against a user's content
--   * RLS — own-row SELECT for the affected user; no INSERT/UPDATE/DELETE
--     for non-service roles (writer is the EF / future trigger)
--   * `get_active_scam_flag(p_user_id UUID)` SECURITY INVOKER RPC that
--     returns the most recent active flag as JSON, or NULL
--
-- Scope NOT in THIS migration:
--   * Population — the `scam_detection` Edge Function does not yet write
--     to `scam_flags` (it only writes to `moderation_queue`). Tracking
--     in a follow-up issue. Until then, `get_active_scam_flag` returns
--     NULL for every user and the UI conditional render harmlessly skips
--     the DSA panel.
--
-- Reference:
--   * docs/audits/2026-04-25-tier1-retrospective.md §R-44
--   * docs/epics/E06-trust-moderation.md §Scam Detection
--   * lib/core/domain/entities/scam_flag_statement.dart  (UI entity)
--   * lib/core/domain/entities/scam_reason.dart          (closed enum)
--
-- DSA Art. 17 + EU AI Act Art. 13 require the user to be told:
--   • what was flagged (`content_ref` + optional `content_display_label`)
--   • why (`reasons[]` — closed enum joined to ScamReason on the client)
--   • by whom — the model identifier (`model_version`) and the policy
--     it applied (`policy_version`)
--   • when (`flagged_at`)
--   • with what confidence (`score` ∈ [0,1])
--
-- Rollback paired in `_rollback/<ts+1>_r44_scam_flags_down.sql`.
-- ──────────────────────────────────────────────────────────────────────────

-- 1. Table

CREATE TABLE public.scam_flags (
  id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID         NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Stable rule identifier across model versions; e.g. 'link_pattern_v3',
  -- 'phone_regex_nl'. Lets appeals aggregate across model rebuilds.
  rule_id         TEXT         NOT NULL CHECK (length(rule_id) BETWEEN 1 AND 128),

  -- Closed-enum reasons mapped to lib/core/domain/entities/scam_reason.dart.
  -- TEXT[] (not enum type) so adding a new reason on the client doesn't
  -- require a coordinated migration; the Dart `fromDb` fallback to `other`
  -- absorbs unknown values.
  reasons         TEXT[]       NOT NULL CHECK (array_length(reasons, 1) >= 1),

  score           NUMERIC(4,3) NOT NULL CHECK (score >= 0 AND score <= 1),

  -- Semver-shaped strings. Required by DSA Art. 17(3)(b) so an appellant
  -- can cite the exact decision-maker even after the model is rebuilt.
  model_version   TEXT         NOT NULL CHECK (length(model_version) BETWEEN 1 AND 64),
  policy_version  TEXT         NOT NULL CHECK (length(policy_version) BETWEEN 1 AND 64),

  flagged_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),

  -- Opaque server reference like 'listing/abc-123' or 'message/xyz' — never
  -- the raw flagged content. The widget renders the reference (or the
  -- optional display label) but the content itself stays in the moderation
  -- queue, not on the user's transparency screen.
  content_ref           TEXT NOT NULL CHECK (length(content_ref) BETWEEN 1 AND 256),
  content_display_label TEXT          CHECK (content_display_label IS NULL
                                             OR length(content_display_label) BETWEEN 1 AND 256),

  -- Cleared by the moderation pipeline if the appeal succeeds; the RPC
  -- only returns active flags so a successful appeal hides the panel.
  is_active   BOOLEAN     NOT NULL DEFAULT true,

  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.scam_flags IS
  'R-44 DSA Art. 17 Statement of Reasons. One row per automated '
  'scam-detection flag against a user. Read by SuspensionGateScreen '
  'via get_active_scam_flag. Writes are service-role only.';

-- 2. Index — supports the get_active_scam_flag query path.

CREATE INDEX idx_scam_flags_user_active_recent
  ON public.scam_flags (user_id, flagged_at DESC)
  WHERE is_active = true;

-- 3. updated_at trigger — reuses the project-wide helper from
--    20260321232641 (verified via pg_proc lookup).

CREATE TRIGGER scam_flags_updated_at
  BEFORE UPDATE ON public.scam_flags
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- 4. RLS

ALTER TABLE public.scam_flags ENABLE ROW LEVEL SECURITY;

-- Affected user can read their own flags. Used by `get_active_scam_flag`
-- (SECURITY INVOKER) so the RPC inherits this check naturally — passing
-- another user's UUID will return NULL.
CREATE POLICY scam_flags_own_select
  ON public.scam_flags
  FOR SELECT
  USING (user_id = (SELECT auth.uid()));

-- Explicit deny-all on writes for non-service roles. Service role bypasses
-- RLS, so the future scam_detection EF / trigger writer can still INSERT.
-- Matches the pattern used by `moderation_queue` (PR #211).
CREATE POLICY scam_flags_deny_writes
  ON public.scam_flags
  FOR ALL
  TO authenticated, anon
  USING (false)
  WITH CHECK (false);

-- 5. RPC — get_active_scam_flag

CREATE OR REPLACE FUNCTION public.get_active_scam_flag(p_user_id UUID)
RETURNS JSONB
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public, pg_catalog
AS $$
  -- Returns the most recent active flag for the given user_id, or NULL.
  -- RLS on `scam_flags` ensures only the affected user (auth.uid() =
  -- user_id) sees their own row; calling for someone else returns NULL.
  -- JSON keys are snake_case to match the on-disk DTO convention; the
  -- `ScamFlagStatementDto.fromJson` parser maps to camelCase.
  SELECT jsonb_build_object(
    'rule_id',               rule_id,
    'reasons',               reasons,
    'score',                 score,
    'model_version',         model_version,
    'policy_version',        policy_version,
    'flagged_at',            flagged_at,
    'content_ref',           content_ref,
    'content_display_label', content_display_label
  )
  FROM public.scam_flags
  WHERE user_id = p_user_id
    AND is_active = true
  ORDER BY flagged_at DESC
  LIMIT 1;
$$;

COMMENT ON FUNCTION public.get_active_scam_flag(UUID) IS
  'Returns the most recent active scam_flags row for the given user as '
  'JSON, or NULL. SECURITY INVOKER: relies on the scam_flags own-row '
  'SELECT policy to scope visibility to the affected user. R-44 / '
  'issue #259.';

REVOKE ALL ON FUNCTION public.get_active_scam_flag(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_active_scam_flag(UUID) TO authenticated;
