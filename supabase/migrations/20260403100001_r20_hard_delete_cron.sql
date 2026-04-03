-- R-20: Hard-delete cron job — runs daily at 03:00 UTC
-- Permanently removes data for users past the 30-day grace period.
-- Transactions and ledger entries are preserved (PSD2 / 7-year audit).

-- Enable pg_cron extension (requires Supabase Pro plan)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Create the hard-delete function
CREATE OR REPLACE FUNCTION gdpr_hard_delete_expired()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  rec RECORD;
  deleted_count INT := 0;
BEGIN
  FOR rec IN
    SELECT id, user_id
    FROM gdpr_deletion_queue
    WHERE status = 'pending'
      AND delete_after < now()
  LOOP
    BEGIN
      -- Delete remaining user data (addresses/prefs already deleted by EF)
      -- These are safety catches in case the Edge Function missed any
      DELETE FROM user_addresses WHERE user_id = rec.user_id;
      DELETE FROM notification_preferences WHERE user_id = rec.user_id;
      DELETE FROM favourites WHERE user_id = rec.user_id;

      -- Anonymize listings (keep for marketplace history, remove PII)
      UPDATE listings
      SET seller_id = '00000000-0000-0000-0000-000000000000',
          deleted_at = COALESCE(deleted_at, now())
      WHERE seller_id = rec.user_id;

      -- Delete user profile (if not already cascade-deleted)
      DELETE FROM user_profiles WHERE id = rec.user_id;

      -- Mark queue entry as completed
      UPDATE gdpr_deletion_queue
      SET status = 'completed', completed_at = now()
      WHERE id = rec.id;

      -- Audit log
      INSERT INTO audit_logs (user_id, action, metadata)
      VALUES (rec.user_id, 'hard_delete_completed', jsonb_build_object(
        'queue_id', rec.id,
        'requested_at', rec.requested_at
      ));

      deleted_count := deleted_count + 1;

    EXCEPTION WHEN OTHERS THEN
      -- Mark as failed but continue with next user
      UPDATE gdpr_deletion_queue
      SET status = 'failed', error_message = SQLERRM
      WHERE id = rec.id;

      INSERT INTO audit_logs (user_id, action, metadata)
      VALUES (rec.user_id, 'hard_delete_failed', jsonb_build_object(
        'queue_id', rec.id,
        'error', SQLERRM
      ));
    END;
  END LOOP;

  IF deleted_count > 0 THEN
    RAISE NOTICE 'GDPR hard-delete completed: % users', deleted_count;
  END IF;
END;
$$;

-- Schedule daily at 03:00 UTC
SELECT cron.schedule(
  'gdpr-hard-delete',
  '0 3 * * *',
  'SELECT gdpr_hard_delete_expired()'
);

-- Add a sentinel row for the anonymized seller references
INSERT INTO user_profiles (id, display_name, kyc_level)
VALUES ('00000000-0000-0000-0000-000000000000', 'Verwijderd account', 'level0')
ON CONFLICT (id) DO NOTHING;
