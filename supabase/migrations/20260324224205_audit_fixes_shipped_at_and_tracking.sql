-- Audit fix: set shipped_at timestamp + expand escrow_deadline trigger

-- Update the set_escrow_deadline function to also handle shipped_at
CREATE OR REPLACE FUNCTION set_escrow_deadline()
RETURNS TRIGGER AS $$
BEGIN
  -- H1: Set shipped_at when transitioning to 'shipped'
  IF NEW.status = 'shipped' AND OLD.status != 'shipped' THEN
    NEW.shipped_at := now();
  END IF;

  -- Set escrow_deadline (48h) when transitioning to 'delivered'
  -- C2: Do NOT overwrite delivered_at — on_tracking_delivered trigger
  -- sets it from the carrier's actual delivery timestamp (occurred_at).
  -- Only set escrow_deadline here.
  IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
    NEW.escrow_deadline := now() + INTERVAL '48 hours';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Expand trigger to also fire on 'shipped' status
DROP TRIGGER IF EXISTS trg_set_escrow_deadline ON transactions;
CREATE TRIGGER trg_set_escrow_deadline
  BEFORE UPDATE ON transactions
  FOR EACH ROW
  WHEN (NEW.status IN ('shipped', 'delivered'))
  EXECUTE FUNCTION set_escrow_deadline();
