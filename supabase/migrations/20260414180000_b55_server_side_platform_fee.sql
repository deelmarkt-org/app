-- B-55 review fix H1: Move platform fee calculation server-side.
--
-- Previously the Flutter client computed platform_fee_cents and sent it
-- in the INSERT payload. A modified client could send 0 to avoid fees.
-- This trigger enforces the 2.5% fee server-side on every INSERT/UPDATE.
--
-- Reference: PR #154 review comment H1

-- Set a default so the column is optional in INSERT statements.
ALTER TABLE transactions
  ALTER COLUMN platform_fee_cents SET DEFAULT 0;

-- Trigger: always (re)calculate platform_fee_cents as ceil(item_amount_cents * 0.025).
CREATE OR REPLACE FUNCTION calculate_platform_fee()
RETURNS TRIGGER AS $$
BEGIN
  NEW.platform_fee_cents := ceil(NEW.item_amount_cents * 0.025);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_calculate_platform_fee
  BEFORE INSERT OR UPDATE OF item_amount_cents ON transactions
  FOR EACH ROW EXECUTE FUNCTION calculate_platform_fee();
