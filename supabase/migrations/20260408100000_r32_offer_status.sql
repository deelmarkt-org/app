-- R-32: "Make an Offer" — offer_status column on messages
-- Adds a lifecycle column for offer-type messages: pending → accepted / declined.
-- Non-offer messages always have offer_status = NULL (enforced by CHECK).
--
-- Design:
--   - offer_status TEXT with 3-value constraint; NULL for non-offer messages
--   - update_offer_status RPC — SECURITY DEFINER, restricted to the listing
--     seller so buyers cannot accept their own offer
--   - Only the current authenticated participant can invoke the RPC
--
-- Reference: docs/epics/E04-messaging.md §Structured "Make an Offer"
--            docs/SPRINT-PLAN.md R-32

-- =============================================================================
-- 1. Add offer_status column to messages
-- =============================================================================

ALTER TABLE messages
  ADD COLUMN offer_status TEXT
    CHECK (offer_status IN ('pending', 'accepted', 'declined'));

-- offer_status must be present iff type = 'offer'
ALTER TABLE messages
  ADD CONSTRAINT offer_status_required CHECK (
    (type = 'offer' AND offer_status IS NOT NULL)
    OR (type != 'offer' AND offer_status IS NULL)
  );

-- Default new offer messages to 'pending'
ALTER TABLE messages
  ALTER COLUMN offer_status SET DEFAULT NULL;

-- =============================================================================
-- 2. Backfill existing offer rows (if any) to 'pending'
-- =============================================================================

UPDATE messages SET offer_status = 'pending' WHERE type = 'offer' AND offer_status IS NULL;

-- =============================================================================
-- 3. RPC: update_offer_status
-- =============================================================================
-- Only the seller (listing owner) may accept or decline an offer.
-- Buyers cannot change the status of their own offers.
-- Re-accepting / re-declining an already-resolved offer is a no-op (idempotent).

CREATE OR REPLACE FUNCTION update_offer_status(
  p_message_id UUID,
  p_new_status TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_current_status TEXT;
BEGIN
  IF p_new_status NOT IN ('accepted', 'declined') THEN
    RAISE EXCEPTION 'Invalid offer status: %', p_new_status;
  END IF;

  -- Verify caller is the seller of the listing linked to this message's conversation
  IF NOT EXISTS (
    SELECT 1
    FROM public.messages m
    JOIN public.conversations c ON c.id = m.conversation_id
    JOIN public.listings l ON l.id = c.listing_id
    WHERE m.id = p_message_id
      AND m.type = 'offer'
      AND l.seller_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Unauthorized: only the seller may respond to an offer';
  END IF;

  SELECT offer_status INTO v_current_status
  FROM public.messages
  WHERE id = p_message_id;

  -- Already resolved — idempotent, do nothing
  IF v_current_status IN ('accepted', 'declined') THEN
    RETURN;
  END IF;

  UPDATE public.messages
  SET offer_status = p_new_status
  WHERE id = p_message_id;
END;
$$;

REVOKE ALL ON FUNCTION update_offer_status(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION update_offer_status(UUID, TEXT) TO authenticated;
