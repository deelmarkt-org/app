-- B-33: Shipping labels + tracking events for delivery → escrow release
-- Links carrier tracking to transaction status updates.
-- When TrackingStatus = 'delivered', transaction transitions to 'delivered',
-- DB trigger sets escrow_deadline (48h), and release-escrow handles payout.

-- =============================================================================
-- 1. Shipping labels (created when seller generates QR — B-25/B-26)
-- =============================================================================
CREATE TABLE shipping_labels (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  transaction_id  UUID NOT NULL REFERENCES transactions(id),
  carrier         TEXT NOT NULL CHECK (carrier IN ('postnl', 'dhl')),
  barcode         TEXT NOT NULL UNIQUE,
  qr_data         TEXT NOT NULL,
  tracking_url    TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_shipping_labels_txn ON shipping_labels (transaction_id);
CREATE INDEX idx_shipping_labels_barcode ON shipping_labels (barcode);

-- Auto-update updated_at
CREATE TRIGGER shipping_labels_updated_at
  BEFORE UPDATE ON shipping_labels
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =============================================================================
-- 2. Tracking events (carrier webhook payloads)
-- =============================================================================
CREATE TABLE tracking_events (
  id                UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  shipping_label_id UUID NOT NULL REFERENCES shipping_labels(id),
  transaction_id    UUID NOT NULL REFERENCES transactions(id),
  carrier_event_id  TEXT NOT NULL UNIQUE,
  status            TEXT NOT NULL,
  description       TEXT,
  location          TEXT,
  occurred_at       TIMESTAMPTZ NOT NULL,
  received_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_tracking_txn ON tracking_events (transaction_id);
CREATE INDEX idx_tracking_status ON tracking_events (status);

-- =============================================================================
-- 3. RLS policies
-- =============================================================================

-- Shipping labels
ALTER TABLE shipping_labels ENABLE ROW LEVEL SECURITY;

CREATE POLICY shipping_labels_select ON shipping_labels
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM transactions t
      WHERE t.id = shipping_labels.transaction_id
        AND (auth.uid() = t.buyer_id OR auth.uid() = t.seller_id)
    )
  );

CREATE POLICY shipping_labels_service_insert ON shipping_labels
  FOR INSERT WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

CREATE POLICY shipping_labels_service_update ON shipping_labels
  FOR UPDATE USING (auth.jwt() ->> 'role' = 'service_role');

-- Tracking events
ALTER TABLE tracking_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY tracking_events_select ON tracking_events
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM transactions t
      WHERE t.id = tracking_events.transaction_id
        AND (auth.uid() = t.buyer_id OR auth.uid() = t.seller_id)
    )
  );

CREATE POLICY tracking_events_service_insert ON tracking_events
  FOR INSERT WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- Append-only — no updates or deletes on tracking events
CREATE POLICY tracking_events_no_update ON tracking_events FOR UPDATE USING (false);
CREATE POLICY tracking_events_no_delete ON tracking_events FOR DELETE USING (false);

-- =============================================================================
-- 4. Auto-transition: when 'delivered' tracking event inserted, update transaction
-- =============================================================================
CREATE OR REPLACE FUNCTION on_tracking_delivered()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'delivered' THEN
    -- Only transition if current status allows it (shipped → delivered)
    UPDATE transactions
    SET status = 'delivered',
        delivered_at = NEW.occurred_at
    WHERE id = NEW.transaction_id
      AND status = 'shipped';
    -- escrow_deadline trigger (trg_set_escrow_deadline) fires automatically
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_on_tracking_delivered
  AFTER INSERT ON tracking_events
  FOR EACH ROW
  WHEN (NEW.status = 'delivered')
  EXECUTE FUNCTION on_tracking_delivered();
