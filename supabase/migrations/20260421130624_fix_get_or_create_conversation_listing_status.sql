-- ──────────────────────────────────────────────────────────────────────────
-- Fix: get_or_create_conversation references non-existent listings.status
--
-- The original function in 20260407120000_r31_messages_conversations.sql
-- gates conversation creation on `listings.status = 'published'`. That
-- column does not exist — `listings` exposes `is_active BOOLEAN` +
-- `is_sold BOOLEAN` (see 20260329161637_phase_a_user_profiles_listings_
-- categories_b39_to_b44.sql §listings). The RPC has been failing at
-- runtime every time the buyer sends their first message to a seller.
--
-- Surfaced by `supabase db lint` during local-stack bootstrap work.
-- Replace the check with the equivalent active/not-sold gate. No other
-- behaviour change — grants and security properties preserved.
-- ──────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION get_or_create_conversation(
  p_listing_id UUID,
  p_buyer_id   UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_conv_id UUID;
BEGIN
  -- Verify the caller is the buyer
  IF auth.uid() != p_buyer_id THEN
    RAISE EXCEPTION 'Unauthorized: caller must be the buyer';
  END IF;

  -- Prevent buyer from messaging their own listing
  IF EXISTS (
    SELECT 1 FROM public.listings WHERE id = p_listing_id AND seller_id = p_buyer_id
  ) THEN
    RAISE EXCEPTION 'Cannot start a conversation on your own listing';
  END IF;

  -- Only allow conversations on active, unsold listings (S-3). The
  -- original migration checked `status = 'published'` which never
  -- existed on this table — listings.is_active + listings.is_sold are
  -- the actual availability flags.
  IF NOT EXISTS (
    SELECT 1 FROM public.listings
    WHERE id = p_listing_id
      AND is_active = true
      AND is_sold = false
  ) THEN
    RAISE EXCEPTION 'Listing is not available for messaging';
  END IF;

  INSERT INTO public.conversations (listing_id, buyer_id)
  VALUES (p_listing_id, p_buyer_id)
  ON CONFLICT (listing_id, buyer_id) DO NOTHING;

  SELECT id INTO v_conv_id
  FROM public.conversations
  WHERE listing_id = p_listing_id AND buyer_id = p_buyer_id;

  RETURN v_conv_id;
END;
$$;

REVOKE ALL ON FUNCTION get_or_create_conversation(UUID, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_or_create_conversation(UUID, UUID) TO authenticated;
