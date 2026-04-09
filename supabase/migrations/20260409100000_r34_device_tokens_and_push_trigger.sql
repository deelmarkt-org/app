-- R-34: Device tokens table + push notification trigger on new messages.
--
-- Architecture:
--   1. device_tokens: stores FCM tokens per user (multi-device support).
--      Users can have multiple active tokens (phone + tablet).
--   2. Database webhook trigger: on INSERT to messages, calls the
--      send-push-notification Edge Function to deliver FCM push.
--
-- The Edge Function resolves the recipient (buyer or seller), checks
-- notification_preferences.messages, and sends via FCM HTTP v1 API.
--
-- Reference: docs/epics/E04-messaging.md §Push notifications

-- =============================================================================
-- 1. device_tokens table
-- =============================================================================

CREATE TABLE device_tokens (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token      TEXT NOT NULL,
  platform   TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- One token per device per user (token is device-unique)
  CONSTRAINT device_tokens_unique_token UNIQUE (token)
);

CREATE INDEX idx_device_tokens_user_id ON device_tokens (user_id);

-- Auto-update updated_at on token refresh
CREATE TRIGGER set_device_tokens_updated_at
  BEFORE UPDATE ON device_tokens
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- =============================================================================
-- 2. RLS — device_tokens
-- =============================================================================

ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

-- Users can only read/write their own tokens
CREATE POLICY device_tokens_own_select ON device_tokens
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

CREATE POLICY device_tokens_own_insert ON device_tokens
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY device_tokens_own_update ON device_tokens
  FOR UPDATE USING ((SELECT auth.uid()) = user_id);

CREATE POLICY device_tokens_own_delete ON device_tokens
  FOR DELETE USING ((SELECT auth.uid()) = user_id);

-- =============================================================================
-- 3. Database webhook: trigger Edge Function on new message
-- =============================================================================
-- Uses Supabase's pg_net extension to call the Edge Function via HTTP.
-- The Edge Function handles recipient resolution, preference checks, and FCM.

CREATE OR REPLACE FUNCTION notify_new_message()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  payload JSONB;
BEGIN
  payload := jsonb_build_object(
    'message_id', NEW.id,
    'conversation_id', NEW.conversation_id,
    'sender_id', NEW.sender_id,
    'text', LEFT(NEW.text, 200),
    'type', NEW.type::TEXT
  );

  PERFORM net.http_post(
    url := current_setting('app.settings.supabase_url')
           || '/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Authorization', 'Bearer '
                       || current_setting('app.settings.service_role_key'),
      'Content-Type', 'application/json'
    ),
    body := payload
  );

  RETURN NEW;
END;
$$;

CREATE TRIGGER messages_send_push_notification
  AFTER INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_message();
