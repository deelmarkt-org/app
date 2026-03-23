-- B-21: Escrow release automation
-- - Trigger to set escrow_deadline (48h) when status → delivered
-- - pg_cron schedule for release-escrow function (every 15 min)

-- =============================================================================
-- 1. Auto-set escrow_deadline when transaction transitions to 'delivered'
-- =============================================================================
CREATE OR REPLACE FUNCTION set_escrow_deadline()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
    NEW.escrow_deadline := now() + INTERVAL '48 hours';
    NEW.delivered_at := now();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_set_escrow_deadline
  BEFORE UPDATE ON transactions
  FOR EACH ROW
  WHEN (NEW.status = 'delivered')
  EXECUTE FUNCTION set_escrow_deadline();

-- =============================================================================
-- 2. Schedule release-escrow (every 15 min)
-- =============================================================================
SELECT cron.schedule(
  'release-escrow',
  '*/15 * * * *',
  $$
  SELECT net.http_post(
    url := current_setting('app.settings.supabase_url') || '/functions/v1/release-escrow',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  );
  $$
);
