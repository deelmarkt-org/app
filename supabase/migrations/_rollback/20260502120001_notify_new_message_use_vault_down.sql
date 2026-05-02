-- ──────────────────────────────────────────────────────────────────────────
-- Paired rollback for 20260502120000_notify_new_message_use_vault.sql
--
-- Restores the pre-#271 trigger definition that read both the URL and the
-- service-role JWT via `current_setting('app.settings.…')`. This will
-- re-introduce the latent `42704: unrecognized configuration parameter`
-- bug if the GUCs aren't set; only roll back if you have an active
-- replacement plan.
-- ──────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.notify_new_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
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
