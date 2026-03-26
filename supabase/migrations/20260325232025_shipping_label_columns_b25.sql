-- B-25/B-26: Add missing columns to shipping_labels for Ectaro hybrid integration.
-- barcode already exists (used by tracking-webhook).
-- New: label_pdf, ship_by_deadline, provider.

ALTER TABLE shipping_labels
  ADD COLUMN IF NOT EXISTS label_pdf        TEXT,
  ADD COLUMN IF NOT EXISTS ship_by_deadline TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS provider         TEXT CHECK (provider IN ('ectaro', 'postnl-direct', 'dhl-direct'));
