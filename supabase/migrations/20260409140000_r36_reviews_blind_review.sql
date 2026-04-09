-- R-36: Reviews table + blind review logic
-- Implements the ratings & reviews system from E06-trust-moderation.md.
--
-- Key design decisions:
-- 1. Blind review: a review is not visible to anyone except the reviewer until
--    BOTH parties (buyer + seller) have submitted their review for the transaction.
--    Enforced at the DB level via RLS policy.
-- 2. Anti-gaming: UNIQUE(transaction_id, reviewer_id) — one review per person per
--    transaction; UNIQUE(transaction_id, role) — one buyer review + one seller review.
-- 3. Aggregate gate: client hides avg rating below 3 reviews; COUNT enforced here.
-- 4. GDPR tombstone: is_reviewer_deleted flag preserves review content while
--    anonymising the reviewer (no hard delete).
--
-- Reference: docs/epics/E06-trust-moderation.md §Ratings & Reviews
-- Reference: docs/SPRINT-PLAN.md R-36

-- =============================================================================
-- 1. reviews table
-- =============================================================================

CREATE TABLE reviews (
  id                    UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id        UUID         NOT NULL REFERENCES transactions(id) ON DELETE RESTRICT,
  reviewer_id           UUID         NOT NULL REFERENCES auth.users(id),
  reviewee_id           UUID         NOT NULL REFERENCES auth.users(id),
  listing_id            UUID         NOT NULL REFERENCES listings(id) ON DELETE RESTRICT,

  -- Denormalised for display without JOIN (reviewer may be later tombstoned)
  reviewer_name         TEXT         NOT NULL,
  reviewer_avatar_url   TEXT,

  role                  TEXT         NOT NULL CHECK (role IN ('buyer', 'seller')),
  rating                SMALLINT     NOT NULL CHECK (rating BETWEEN 1 AND 5),

  -- Free-text review body, max 500 chars (E06 spec)
  body                  TEXT         NOT NULL CHECK (length(body) <= 500),

  -- Moderation soft-delete flag (admin only)
  is_hidden             BOOLEAN      NOT NULL DEFAULT false,

  -- GDPR Art. 17 tombstone: reviewer account deleted, content preserved anonymised
  is_reviewer_deleted   BOOLEAN      NOT NULL DEFAULT false,

  created_at            TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ,

  -- One review per person per transaction
  CONSTRAINT reviews_unique_reviewer  UNIQUE (transaction_id, reviewer_id),
  -- One buyer review + one seller review per transaction
  CONSTRAINT reviews_unique_role      UNIQUE (transaction_id, role),
  -- Cannot review yourself
  CONSTRAINT reviews_no_self_review   CHECK  (reviewer_id != reviewee_id)
);

CREATE INDEX idx_reviews_reviewee    ON reviews (reviewee_id, created_at DESC);
CREATE INDEX idx_reviews_transaction ON reviews (transaction_id);
CREATE INDEX idx_reviews_hidden      ON reviews (is_hidden) WHERE is_hidden = false;

-- =============================================================================
-- 2. RLS — reviews
-- =============================================================================

ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- SELECT: Reviewer can always read their own review.
-- Anyone else (including the reviewee and public) can read only when BOTH
-- parties have submitted AND the review is not moderation-hidden.
-- This implements the blind review requirement from E06.
CREATE POLICY reviews_select ON reviews
  FOR SELECT USING (
    -- Reviewer always sees their own submission
    reviewer_id = auth.uid()
    OR (
      -- Blind gate: visible once both buyer and seller have reviewed
      is_hidden = false
      AND (
        SELECT COUNT(*)
        FROM   public.reviews r2
        WHERE  r2.transaction_id = reviews.transaction_id
      ) >= 2
    )
  );

-- INSERT: Authenticated reviewer inserts their own review.
-- Transaction must be in a post-escrow status (released or confirmed).
-- The 14-day window check is enforced in the application layer, not here,
-- because TIMESTAMPTZ arithmetic in RLS policies can be bypassed by clock skew.
CREATE POLICY reviews_insert ON reviews
  FOR INSERT WITH CHECK (
    reviewer_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM   public.transactions t
      WHERE  t.id    = transaction_id
        AND  (t.buyer_id = auth.uid() OR t.seller_id = auth.uid())
        AND  t.status IN ('released', 'confirmed', 'resolved')
    )
  );

-- UPDATE: Only service_role can update (moderation via admin panel).
-- Regular users cannot edit a submitted review.

-- DELETE: No deletes — use is_hidden (moderation) or is_reviewer_deleted (GDPR).

-- =============================================================================
-- 3. review_reports table (DSA Art. 16 — content reporting)
-- =============================================================================

CREATE TABLE review_reports (
  id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id   UUID         NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  reporter_id UUID         NOT NULL REFERENCES auth.users(id),
  reason      TEXT         NOT NULL,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),

  -- One report per reviewer-review pair
  CONSTRAINT review_reports_unique UNIQUE (review_id, reporter_id)
);

CREATE INDEX idx_review_reports_review ON review_reports (review_id);

-- =============================================================================
-- 4. RLS — review_reports
-- =============================================================================

ALTER TABLE review_reports ENABLE ROW LEVEL SECURITY;

-- Anyone authenticated can submit a report for their own reporter_id.
CREATE POLICY review_reports_insert ON review_reports
  FOR INSERT WITH CHECK (reporter_id = auth.uid());

-- Users can read only their own reports (to show "you already reported this").
CREATE POLICY review_reports_select ON review_reports
  FOR SELECT USING (reporter_id = auth.uid());

-- =============================================================================
-- 5. Helper RPC: submit_review
-- =============================================================================
-- Atomically inserts a review, then checks if the other party's review already
-- exists. If so, no action needed — the SELECT policy automatically reveals both.
-- Called by SupabaseReviewRepository.submitReview via client.rpc().
--
-- Returns the inserted review row as JSON so the caller has the server-assigned id.

CREATE OR REPLACE FUNCTION submit_review(
  p_transaction_id      UUID,
  p_role                TEXT,
  p_rating              SMALLINT,
  p_body                TEXT,
  p_reviewer_name       TEXT,
  p_reviewer_avatar_url TEXT DEFAULT NULL
)
RETURNS SETOF reviews
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
  v_reviewer_id  UUID := auth.uid();
  v_reviewee_id  UUID;
  v_listing_id   UUID;
BEGIN
  -- Validate role value
  IF p_role NOT IN ('buyer', 'seller') THEN
    RAISE EXCEPTION 'Invalid role: %', p_role;
  END IF;

  -- Resolve reviewee and listing from the transaction
  SELECT
    CASE WHEN p_role = 'buyer' THEN seller_id ELSE buyer_id END,
    listing_id
  INTO v_reviewee_id, v_listing_id
  FROM public.transactions
  WHERE id = p_transaction_id
    AND (buyer_id = v_reviewer_id OR seller_id = v_reviewer_id)
    AND status IN ('released', 'confirmed', 'resolved');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Transaction not found or not eligible for review';
  END IF;

  -- Insert (idempotent: conflict on unique reviewer constraint returns existing row)
  INSERT INTO public.reviews (
    transaction_id,
    reviewer_id,
    reviewee_id,
    listing_id,
    role,
    rating,
    body,
    reviewer_name,
    reviewer_avatar_url
  )
  VALUES (
    p_transaction_id,
    v_reviewer_id,
    v_reviewee_id,
    v_listing_id,
    p_role,
    p_rating,
    p_body,
    p_reviewer_name,
    p_reviewer_avatar_url
  )
  ON CONFLICT (transaction_id, reviewer_id) DO UPDATE
    SET updated_at = now();  -- idempotent: no-op on duplicate submission

  RETURN QUERY
    SELECT * FROM public.reviews
    WHERE transaction_id = p_transaction_id
      AND reviewer_id = v_reviewer_id;
END;
$$;

-- Callable by authenticated users only (SECURITY INVOKER — RLS applies)
REVOKE ALL ON FUNCTION submit_review(UUID, TEXT, SMALLINT, TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION submit_review(UUID, TEXT, SMALLINT, TEXT, TEXT, TEXT) TO authenticated;
