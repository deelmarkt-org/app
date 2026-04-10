-- R-35: Scam detection moderation queue
-- Creates a `moderation_queue` table for moderators to review AI-flagged messages.
-- The scam_confidence / scam_reasons / scam_flagged_at columns already exist on
-- `messages` (created in R-31 migration). This migration adds the moderator
-- review workflow.
--
-- Reference: docs/epics/E06-trust-moderation.md, docs/SPRINT-PLAN.md R-35

-- =============================================================================
-- 1. moderation_queue table
-- =============================================================================
-- One row per flagged message. Created by the scam-detection Edge Function,
-- reviewed by moderators via admin panel.

CREATE TYPE moderation_status AS ENUM ('pending', 'confirmed', 'dismissed');

CREATE TABLE moderation_queue (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id     UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  flagged_by     TEXT NOT NULL DEFAULT 'scam-detection-v1',  -- identifies the detection version
  confidence     TEXT NOT NULL CHECK (confidence IN ('low', 'high')),
  reasons        TEXT[] NOT NULL,
  status         moderation_status NOT NULL DEFAULT 'pending',
  reviewed_by    UUID REFERENCES auth.users(id),
  reviewed_at    TIMESTAMPTZ,
  action_taken   TEXT,  -- e.g. 'message_hidden', 'user_warned', 'user_suspended'
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- One queue entry per message
  CONSTRAINT moderation_queue_unique_message UNIQUE (message_id)
);

CREATE INDEX idx_moderation_queue_status ON moderation_queue (status) WHERE status = 'pending';
CREATE INDEX idx_moderation_queue_created ON moderation_queue (created_at DESC);
CREATE INDEX idx_moderation_queue_conversation ON moderation_queue (conversation_id);

-- =============================================================================
-- 2. RLS — moderation_queue
-- =============================================================================
-- Only service_role can insert (Edge Function). Moderators read/update via admin panel
-- (service_role or a future moderator role).

ALTER TABLE moderation_queue ENABLE ROW LEVEL SECURITY;

-- No public access — all operations go through service_role or admin RPCs.
-- The Edge Function uses service_role key to insert.

-- =============================================================================
-- 3. RPC: flag_message_scam (called by scam-detection Edge Function)
-- =============================================================================
-- Atomically updates the message scam fields AND inserts into moderation_queue.
-- SECURITY DEFINER with service_role — not callable by regular users.

CREATE OR REPLACE FUNCTION flag_message_scam(
  p_message_id     UUID,
  p_conversation_id UUID,
  p_confidence     TEXT,
  p_reasons        TEXT[]
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- Update message scam fields
  UPDATE public.messages
  SET scam_confidence = p_confidence,
      scam_reasons    = p_reasons,
      scam_flagged_at = now()
  WHERE id = p_message_id;

  -- Insert into moderation queue (ignore if already flagged)
  INSERT INTO public.moderation_queue (message_id, conversation_id, confidence, reasons)
  VALUES (p_message_id, p_conversation_id, p_confidence, p_reasons)
  ON CONFLICT (message_id) DO NOTHING;
END;
$$;

REVOKE ALL ON FUNCTION flag_message_scam(UUID, UUID, TEXT, TEXT[]) FROM PUBLIC;
-- Only service_role can call this (Edge Function uses service_role key)
