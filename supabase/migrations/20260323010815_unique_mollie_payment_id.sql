-- Audit fix: enforce uniqueness on mollie_payment_id
-- Mollie guarantees unique payment IDs, but DB should enforce it too.
-- Partial unique index (WHERE NOT NULL) since column is nullable.

CREATE UNIQUE INDEX unq_mollie_payment_id
  ON transactions (mollie_payment_id)
  WHERE mollie_payment_id IS NOT NULL;

-- Drop the old non-unique partial index (superseded)
DROP INDEX IF EXISTS idx_transactions_mollie;
