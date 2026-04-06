-- R-20: Hard-delete cron job — runs daily at 03:00 UTC
-- Permanently removes data for users past the 30-day grace period.
-- Transactions and ledger entries are preserved (PSD2 / 7-year audit).
--
-- Two-stage GDPR erasure:
--   Stage 1 (this function): delete profile/addresses/prefs/favourites +
--           anonymize listings. Marks status='completed', auth_deleted=false.
--   Stage 2 (gdpr-cleanup-auth Edge Function, scheduled separately):
--           calls auth.admin.deleteUser() and sets auth_deleted=true.
--
-- auth.users deletion requires the Supabase admin API and cannot run from
-- SQL on Supabase Cloud, hence the split. Keeping PII erasure independent
-- of auth API availability is intentional — GDPR compliance prioritizes
-- the removal of personal data over credential record cleanup.

CREATE EXTENSION IF NOT EXISTS pg_cron;

-- C-2: Hardened search_path, no public execute
CREATE OR REPLACE FUNCTION gdpr_hard_delete_expired()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
  rec RECORD;
  deleted_count INT := 0;
BEGIN
  FOR rec IN
    SELECT id, user_id, requested_at
    FROM gdpr_deletion_queue
    WHERE status = 'pending'
      AND delete_after < now()
  LOOP
    BEGIN
      -- M-4: Safety deletes (defense-in-depth — soft_delete_account
      -- already ran these, but handles edge cases like partial failures)
      DELETE FROM user_addresses WHERE user_id = rec.user_id;
      DELETE FROM notification_preferences WHERE user_id = rec.user_id;
      DELETE FROM favourites WHERE user_id = rec.user_id;

      -- Anonymize listings — null out seller FK, mark deleted
      UPDATE listings
      SET seller_id = NULL,
          deleted_at = COALESCE(deleted_at, now())
      WHERE seller_id = rec.user_id;

      -- Delete user profile
      DELETE FROM user_profiles WHERE id = rec.user_id;

      -- Mark PII erasure complete. auth_deleted remains false until the
      -- gdpr-cleanup-auth Edge Function runs the admin API call (Stage 2).
      UPDATE gdpr_deletion_queue
      SET status = 'completed', completed_at = now()
      WHERE id = rec.id;

      INSERT INTO audit_logs (user_id, action, metadata)
      VALUES (rec.user_id, 'hard_delete_completed', jsonb_build_object(
        'queue_id', rec.id,
        'requested_at', rec.requested_at
      ));

      deleted_count := deleted_count + 1;

    EXCEPTION WHEN OTHERS THEN
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

-- C-2: Restrict to pg_cron only (no public execute)
REVOKE ALL ON FUNCTION gdpr_hard_delete_expired() FROM PUBLIC;

-- M-3: Idempotent cron scheduling
SELECT cron.unschedule('gdpr-hard-delete');
SELECT cron.schedule(
  'gdpr-hard-delete',
  '0 3 * * *',
  'SELECT gdpr_hard_delete_expired()'
);
