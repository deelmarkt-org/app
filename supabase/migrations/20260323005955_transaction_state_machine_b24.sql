-- B-24: Transaction status state machine enforcement
-- Mirrors Dart TransactionStatus.validTransitions exactly.
-- Prevents invalid state transitions at the DB level.
--
-- State machine:
--   created → {payment_pending, cancelled}
--   payment_pending → {paid, expired, failed, cancelled}
--   paid → {shipped}
--   shipped → {delivered}
--   delivered → {confirmed, disputed}
--   confirmed → {released}
--   disputed → {resolved, refunded}
--   released, expired, failed, resolved, refunded, cancelled → (terminal)

CREATE OR REPLACE FUNCTION validate_transaction_status_transition()
RETURNS TRIGGER AS $$
BEGIN
  -- Allow same-status updates (no transition)
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  -- Validate transition against state machine
  IF NOT (
    (OLD.status = 'created' AND NEW.status IN ('payment_pending', 'cancelled'))
    OR (OLD.status = 'payment_pending' AND NEW.status IN ('paid', 'expired', 'failed', 'cancelled'))
    OR (OLD.status = 'paid' AND NEW.status IN ('shipped'))
    OR (OLD.status = 'shipped' AND NEW.status IN ('delivered'))
    OR (OLD.status = 'delivered' AND NEW.status IN ('confirmed', 'disputed'))
    OR (OLD.status = 'confirmed' AND NEW.status IN ('released'))
    OR (OLD.status = 'disputed' AND NEW.status IN ('resolved', 'refunded'))
  ) THEN
    RAISE EXCEPTION 'Invalid status transition: % → %', OLD.status, NEW.status
      USING HINT = 'Check TransactionStatus.validTransitions in Dart for allowed transitions.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_status_transition
  BEFORE UPDATE ON transactions
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION validate_transaction_status_transition();
