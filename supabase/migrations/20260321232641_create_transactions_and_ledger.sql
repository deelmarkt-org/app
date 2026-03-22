-- B-17: Transactions table + Double-entry escrow ledger
-- Reference: docs/ARCHITECTURE.md §Double-Entry Escrow Ledger
-- Reference: docs/epics/E03-payments-escrow.md

-- =============================================================================
-- 1. Transaction status enum (mirrors TransactionStatus in Dart)
-- =============================================================================
CREATE TYPE transaction_status AS ENUM (
  'created',
  'payment_pending',
  'paid',
  'shipped',
  'delivered',
  'confirmed',
  'released',
  'expired',
  'failed',
  'disputed',
  'resolved',
  'refunded',
  'cancelled'
);

-- =============================================================================
-- 2. Transactions table
-- =============================================================================
CREATE TABLE transactions (
  id                  UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  listing_id          UUID NOT NULL, -- TODO: Add REFERENCES listings(id) when listings table is created (E01)
  buyer_id            UUID NOT NULL REFERENCES auth.users(id),
  seller_id           UUID NOT NULL REFERENCES auth.users(id),
  status              transaction_status NOT NULL DEFAULT 'created',
  item_amount_cents   INTEGER NOT NULL CHECK (item_amount_cents > 0),
  platform_fee_cents  INTEGER NOT NULL CHECK (platform_fee_cents >= 0),
  shipping_cost_cents INTEGER NOT NULL CHECK (shipping_cost_cents >= 0),
  currency            CHAR(3) NOT NULL DEFAULT 'EUR',
  mollie_payment_id   TEXT,
  paid_at             TIMESTAMPTZ,
  shipped_at          TIMESTAMPTZ,
  delivered_at        TIMESTAMPTZ,
  confirmed_at        TIMESTAMPTZ,
  released_at         TIMESTAMPTZ,
  disputed_at         TIMESTAMPTZ,
  escrow_deadline     TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT buyer_not_seller CHECK (buyer_id != seller_id)
);

-- Index for common queries
CREATE INDEX idx_transactions_buyer ON transactions (buyer_id);
CREATE INDEX idx_transactions_seller ON transactions (seller_id);
CREATE INDEX idx_transactions_listing ON transactions (listing_id);
CREATE INDEX idx_transactions_status ON transactions (status);
CREATE INDEX idx_transactions_mollie ON transactions (mollie_payment_id) WHERE mollie_payment_id IS NOT NULL;

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER transactions_updated_at
  BEFORE UPDATE ON transactions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =============================================================================
-- 3. Transactions RLS
-- =============================================================================
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Buyers and sellers can read their own transactions
CREATE POLICY transactions_select ON transactions
  FOR SELECT USING (
    auth.uid() = buyer_id OR auth.uid() = seller_id
  );

-- Only authenticated users can create transactions (as buyer)
CREATE POLICY transactions_insert ON transactions
  FOR INSERT WITH CHECK (
    auth.uid() = buyer_id
  );

-- Status updates only via service_role (Edge Functions)
-- No direct UPDATE policy for authenticated users
CREATE POLICY transactions_service_update ON transactions
  FOR UPDATE USING (
    auth.jwt() ->> 'role' = 'service_role'
  );

-- =============================================================================
-- 4. Ledger entries table (append-only, PSD2 compliant)
-- =============================================================================
CREATE TABLE ledger_entries (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  transaction_id  UUID NOT NULL REFERENCES transactions(id),
  idempotency_key TEXT NOT NULL UNIQUE,
  debit_account   TEXT NOT NULL,
  credit_account  TEXT NOT NULL,
  amount_cents    INTEGER NOT NULL CHECK (amount_cents > 0),
  currency        CHAR(3) NOT NULL DEFAULT 'EUR',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for transaction lookups and reconciliation
CREATE INDEX idx_ledger_transaction ON ledger_entries (transaction_id);
CREATE INDEX idx_ledger_debit ON ledger_entries (debit_account);
CREATE INDEX idx_ledger_credit ON ledger_entries (credit_account);
CREATE INDEX idx_ledger_created ON ledger_entries (created_at);

-- =============================================================================
-- 5. Ledger RLS — append-only (no UPDATE or DELETE)
-- =============================================================================
ALTER TABLE ledger_entries ENABLE ROW LEVEL SECURITY;

-- Only service_role (Edge Functions) can insert ledger entries
CREATE POLICY ledger_insert ON ledger_entries
  FOR INSERT WITH CHECK (
    auth.jwt() ->> 'role' = 'service_role'
  );

-- Buyers and sellers can read ledger entries for their transactions
CREATE POLICY ledger_select ON ledger_entries
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM transactions t
      WHERE t.id = ledger_entries.transaction_id
        AND (auth.uid() = t.buyer_id OR auth.uid() = t.seller_id)
    )
  );

-- Append-only: explicitly deny UPDATE and DELETE
CREATE POLICY ledger_no_update ON ledger_entries FOR UPDATE USING (false);
CREATE POLICY ledger_no_delete ON ledger_entries FOR DELETE USING (false);

-- =============================================================================
-- 6. Webhook events table (for reconciliation — B-18)
-- =============================================================================
CREATE TABLE mollie_webhook_events (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  mollie_id       TEXT NOT NULL,
  event_type      TEXT NOT NULL,
  payload         JSONB NOT NULL,
  processed       BOOLEAN NOT NULL DEFAULT false,
  idempotency_key TEXT NOT NULL UNIQUE,
  attempts        INTEGER NOT NULL DEFAULT 0,
  last_error      TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  processed_at    TIMESTAMPTZ
);

CREATE INDEX idx_webhook_mollie_id ON mollie_webhook_events (mollie_id);
CREATE INDEX idx_webhook_processed ON mollie_webhook_events (processed) WHERE NOT processed;
CREATE INDEX idx_webhook_created ON mollie_webhook_events (created_at);

-- Webhook events RLS — service_role only
ALTER TABLE mollie_webhook_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY webhook_service_insert ON mollie_webhook_events
  FOR INSERT WITH CHECK (
    auth.jwt() ->> 'role' = 'service_role'
  );

CREATE POLICY webhook_service_select ON mollie_webhook_events
  FOR SELECT USING (
    auth.jwt() ->> 'role' = 'service_role'
  );

CREATE POLICY webhook_service_update ON mollie_webhook_events
  FOR UPDATE USING (
    auth.jwt() ->> 'role' = 'service_role'
  );
