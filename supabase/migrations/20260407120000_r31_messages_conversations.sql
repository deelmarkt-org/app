-- R-31: Messages table + Supabase Realtime
-- Creates `conversations` and `messages` tables for E04 in-app messaging.
-- Enables Supabase Realtime publication on `messages` for WebSocket delivery.
--
-- Design:
--   - conversations: one per (listing, buyer) pair — enforced by unique index
--   - messages: append-only with FK to conversations
--   - RLS: participants-only access (buyer + seller derived from listing)
--   - Realtime: enabled on messages via supabase_realtime publication
--
-- Reference: docs/epics/E04-messaging.md, docs/SPRINT-PLAN.md R-31

-- =============================================================================
-- 1. message_type enum
-- =============================================================================

CREATE TYPE message_type AS ENUM ('text', 'offer', 'system_alert', 'scam_warning');

-- =============================================================================
-- 2. conversations table
-- =============================================================================
-- Links a buyer to a listing. One conversation per (listing_id, buyer_id) pair.
-- The seller is always the listing owner — resolved via FK join.

CREATE TABLE conversations (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id     UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  buyer_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_message_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- One active conversation per buyer per listing
  CONSTRAINT conversations_unique_listing_buyer UNIQUE (listing_id, buyer_id)
);

CREATE INDEX idx_conversations_listing_id ON conversations (listing_id);
CREATE INDEX idx_conversations_buyer_id ON conversations (buyer_id);
CREATE INDEX idx_conversations_last_message_at ON conversations (last_message_at DESC);

-- Prevent clients from spoofing timestamps via PostgREST INSERT (S-4).
CREATE OR REPLACE FUNCTION conversations_set_timestamps()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.created_at := now();
  NEW.last_message_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER conversations_enforce_timestamps
  BEFORE INSERT ON conversations
  FOR EACH ROW
  EXECUTE FUNCTION conversations_set_timestamps();

-- =============================================================================
-- 3. messages table
-- =============================================================================

CREATE TABLE messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  text            TEXT NOT NULL CHECK (char_length(text) BETWEEN 1 AND 2000),
  type            message_type NOT NULL DEFAULT 'text',
  is_read         BOOLEAN NOT NULL DEFAULT false,

  -- E06 scam detection fields (populated asynchronously by R-35 Edge Function)
  scam_confidence TEXT CHECK (scam_confidence IN ('none', 'low', 'high')) DEFAULT 'none',
  scam_reasons    TEXT[],
  scam_flagged_at TIMESTAMPTZ,

  -- Offer-type fields (non-null only when type = 'offer')
  offer_amount_cents INTEGER CHECK (offer_amount_cents > 0),

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- scam invariant: confidence must align with presence of reasons
  CONSTRAINT scam_fields_consistent CHECK (
    (scam_confidence = 'none' AND scam_reasons IS NULL AND scam_flagged_at IS NULL)
    OR
    (scam_confidence IN ('low', 'high') AND scam_reasons IS NOT NULL AND scam_flagged_at IS NOT NULL)
  ),

  -- offer_amount_cents must be present iff type = 'offer'
  CONSTRAINT offer_amount_required CHECK (
    (type = 'offer' AND offer_amount_cents IS NOT NULL)
    OR (type != 'offer' AND offer_amount_cents IS NULL)
  )
);

CREATE INDEX idx_messages_conversation_id ON messages (conversation_id, created_at);
CREATE INDEX idx_messages_sender_id ON messages (sender_id);
CREATE INDEX idx_messages_unread ON messages (conversation_id) WHERE is_read = false;

-- =============================================================================
-- 4. Auto-update conversations.last_message_at on INSERT
-- =============================================================================

CREATE OR REPLACE FUNCTION update_conversation_last_message_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  UPDATE conversations
  SET last_message_at = NEW.created_at
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$;

CREATE TRIGGER messages_update_conversation_ts
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION update_conversation_last_message_at();

-- =============================================================================
-- 5. RLS — conversations
-- =============================================================================

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

-- Buyer can see their own conversations
CREATE POLICY conversations_buyer_select ON conversations
  FOR SELECT USING (auth.uid() = buyer_id);

-- Seller can see conversations about their listings
CREATE POLICY conversations_seller_select ON conversations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM listings
      WHERE listings.id = conversations.listing_id
        AND listings.seller_id = auth.uid()
    )
  );

-- Only the buyer can start a conversation (one per listing per buyer)
CREATE POLICY conversations_buyer_insert ON conversations
  FOR INSERT WITH CHECK (auth.uid() = buyer_id);

-- =============================================================================
-- 6. RLS — messages
-- =============================================================================

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Participants (buyer or seller) can read messages in their conversations
CREATE POLICY messages_participant_select ON messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM conversations c
      JOIN listings l ON l.id = c.listing_id
      WHERE c.id = messages.conversation_id
        AND (c.buyer_id = auth.uid() OR l.seller_id = auth.uid())
    )
  );

-- Only participants can send messages
CREATE POLICY messages_participant_insert ON messages
  FOR INSERT WITH CHECK (
    auth.uid() = sender_id
    AND EXISTS (
      SELECT 1 FROM conversations c
      JOIN listings l ON l.id = c.listing_id
      WHERE c.id = messages.conversation_id
        AND (c.buyer_id = auth.uid() OR l.seller_id = auth.uid())
    )
  );

-- =============================================================================
-- 7. Supabase Realtime — enable on messages
-- =============================================================================
-- Adds the messages table to the supabase_realtime publication so clients
-- can subscribe via channel.onPostgresChanges(). RLS governs what each
-- subscriber receives.

ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- =============================================================================
-- 7.5. mark_message_read — secure RPC replacing the UPDATE RLS policy
-- =============================================================================
-- Replacing a permissive UPDATE policy: the old policy only constrained
-- `is_read = true` via WITH CHECK but did not restrict which OTHER columns
-- could be mutated. This RPC limits the UPDATE to a single column.

CREATE OR REPLACE FUNCTION mark_message_read(p_message_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  UPDATE public.messages
  SET is_read = true
  WHERE id = p_message_id
    AND sender_id != auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.conversations c
      JOIN public.listings l ON l.id = c.listing_id
      WHERE c.id = public.messages.conversation_id
        AND (c.buyer_id = auth.uid() OR l.seller_id = auth.uid())
    );
END;
$$;

REVOKE ALL ON FUNCTION mark_message_read(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION mark_message_read(UUID) TO authenticated;

-- =============================================================================
-- 8. Helper RPC: get_or_create_conversation
-- =============================================================================
-- Atomically returns an existing conversation or inserts a new one.
-- Prevents race conditions on first message from a buyer.

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

  -- Only allow conversations on published listings (S-3)
  IF NOT EXISTS (
    SELECT 1 FROM public.listings WHERE id = p_listing_id AND status = 'published'
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

-- =============================================================================
-- 9. Helper RPC: get_conversations_for_user
-- =============================================================================
-- Returns enriched conversation rows for the current user (buyer or seller),
-- including listing thumbnail, other participant name, and unread count.
-- Used by ConversationListScreen to avoid N+1 queries.

CREATE OR REPLACE FUNCTION get_conversations_for_user()
RETURNS TABLE (
  id               UUID,
  listing_id       UUID,
  listing_title    TEXT,
  listing_image_url TEXT,
  other_user_id    UUID,
  other_user_name  TEXT,
  other_user_avatar_url TEXT,
  last_message_text TEXT,
  last_message_at  TIMESTAMPTZ,
  unread_count     BIGINT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT
    c.id,
    c.listing_id,
    l.title                    AS listing_title,
    l.image_urls[1]            AS listing_image_url,
    CASE
      WHEN c.buyer_id = auth.uid() THEN l.seller_id
      ELSE c.buyer_id
    END                        AS other_user_id,
    CASE
      WHEN c.buyer_id = auth.uid() THEN seller_profile.display_name
      ELSE buyer_profile.display_name
    END                        AS other_user_name,
    CASE
      WHEN c.buyer_id = auth.uid() THEN seller_profile.avatar_url
      ELSE buyer_profile.avatar_url
    END                        AS other_user_avatar_url,
    last_msg.text              AS last_message_text,
    c.last_message_at,
    COALESCE(unread.cnt, 0)    AS unread_count
  FROM public.conversations c
  JOIN public.listings l ON l.id = c.listing_id
  JOIN public.user_profiles buyer_profile ON buyer_profile.id = c.buyer_id
  JOIN public.user_profiles seller_profile ON seller_profile.id = l.seller_id
  LEFT JOIN LATERAL (
    SELECT text FROM public.messages
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
