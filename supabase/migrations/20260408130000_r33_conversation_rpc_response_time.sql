-- R-33: Expose seller_response_time_minutes in get_conversations_for_user RPC.
--
-- The seller_profile join already exists (added in R-31). This migration
-- adds response_time_minutes to the RETURNS TABLE and SELECT list so the
-- Flutter ChatHeader can display "Responds within 1 hour" per the E04 epic
-- (docs/epics/E04-messaging.md §Seller Response Time, user story line 25).
--
-- Note: only the seller's response time is meaningful in a conversation —
-- we always expose seller_profile.response_time_minutes regardless of
-- whether the current user is the buyer or seller.
--
-- Reference: docs/epics/E04-messaging.md R-33 audit finding

CREATE OR REPLACE FUNCTION get_conversations_for_user()
RETURNS TABLE (
  id                           UUID,
  listing_id                   UUID,
  listing_title                TEXT,
  listing_image_url            TEXT,
  other_user_id                UUID,
  other_user_name              TEXT,
  other_user_avatar_url        TEXT,
  last_message_text            TEXT,
  last_message_type            TEXT,
  last_message_at              TIMESTAMPTZ,
  unread_count                 BIGINT,
  seller_response_time_minutes INTEGER
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT
    c.id,
    c.listing_id,
    l.title                          AS listing_title,
    l.image_urls[1]                  AS listing_image_url,
    CASE
      WHEN c.buyer_id = auth.uid() THEN l.seller_id
      ELSE c.buyer_id
    END                              AS other_user_id,
    CASE
      WHEN c.buyer_id = auth.uid() THEN seller_profile.display_name
      ELSE buyer_profile.display_name
    END                              AS other_user_name,
    CASE
      WHEN c.buyer_id = auth.uid() THEN seller_profile.avatar_url
      ELSE buyer_profile.avatar_url
    END                              AS other_user_avatar_url,
    last_msg.text                    AS last_message_text,
    last_msg.type::TEXT              AS last_message_type,
    c.last_message_at,
    COALESCE(unread.cnt, 0)          AS unread_count,
    seller_profile.response_time_minutes AS seller_response_time_minutes
  FROM public.conversations c
  JOIN public.listings l ON l.id = c.listing_id
  JOIN public.user_profiles buyer_profile ON buyer_profile.id = c.buyer_id
  JOIN public.user_profiles seller_profile ON seller_profile.id = l.seller_id
  LEFT JOIN LATERAL (
    SELECT text, type FROM public.messages
    WHERE conversation_id = c.id
    ORDER BY created_at DESC
    LIMIT 1
  ) last_msg ON true
  LEFT JOIN LATERAL (
    SELECT COUNT(*) AS cnt FROM public.messages
    WHERE conversation_id = c.id
      AND is_read = false
      AND sender_id != auth.uid()
  ) unread ON true
  WHERE c.buyer_id = auth.uid()
     OR l.seller_id = auth.uid()
  ORDER BY c.last_message_at DESC;
$$;

REVOKE ALL ON FUNCTION get_conversations_for_user() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_conversations_for_user() TO authenticated;
