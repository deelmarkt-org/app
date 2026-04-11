-- R-29: search_outbox table + listing trigger
--
-- Implements the outbox pattern for downstream cache/search sync:
--   • Every INSERT / UPDATE / DELETE on listings writes a row here.
--   • The process-search-outbox Edge Function (R-30) polls this table,
--     invalidates Redis caches, and marks rows as processed.
--
-- Accepted event_type values:
--   listing.created  — new listing published
--   listing.updated  — any field change (title, price, photos …)
--   listing.sold     — is_sold flipped true  → must leave search immediately
--   listing.deleted  — is_active flipped false (soft-delete) or hard-DELETE
--
-- The payload JSONB always contains:
--   listing_id  UUID   — primary key of the affected listing
--   seller_id   UUID   — seller's user_id (for user-profile cache busting)
--   is_active   BOOL
--   is_sold     BOOL
--
-- Reference: docs/epics/E01-listing-management.md §"Outbox pattern"

-- ---------------------------------------------------------------------------
-- Table
-- ---------------------------------------------------------------------------

CREATE TABLE search_outbox (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type  TEXT        NOT NULL
    CHECK (event_type IN (
      'listing.created',
      'listing.updated',
      'listing.sold',
      'listing.deleted'
    )),
  payload     JSONB       NOT NULL,
  processed   BOOLEAN     NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  processed_at TIMESTAMPTZ
);

-- Fast scan for the cron poller — only unprocessed, ordered oldest-first.
CREATE INDEX idx_search_outbox_unprocessed
  ON search_outbox (created_at ASC)
  WHERE processed = false;

-- Constraint: processed rows must have a processed_at timestamp.
ALTER TABLE search_outbox
  ADD CONSTRAINT search_outbox_processed_requires_timestamp
  CHECK (processed = false OR processed_at IS NOT NULL);

-- ---------------------------------------------------------------------------
-- RLS — service role only (no user access needed)
-- ---------------------------------------------------------------------------

ALTER TABLE search_outbox ENABLE ROW LEVEL SECURITY;
-- No SELECT/INSERT/UPDATE policy for users — all writes via SECURITY DEFINER
-- trigger; all reads by service-role EF bypass RLS automatically.

-- ---------------------------------------------------------------------------
-- Trigger function: notify_search_outbox
-- ---------------------------------------------------------------------------
-- Classifies each listing mutation into a semantic event_type and writes a
-- row to search_outbox.  Called AFTER the row change so NEW/OLD are stable.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION notify_search_outbox()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_event_type TEXT;
  v_listing_id UUID;
  v_seller_id  UUID;
  v_is_active  BOOLEAN;
  v_is_sold    BOOLEAN;
BEGIN
  -- Resolve row data depending on operation
  IF TG_OP = 'DELETE' THEN
    v_listing_id := OLD.id;
    v_seller_id  := OLD.seller_id;
    v_is_active  := false;
    v_is_sold    := OLD.is_sold;
    v_event_type := 'listing.deleted';
  ELSE
    v_listing_id := NEW.id;
    v_seller_id  := NEW.seller_id;
    v_is_active  := NEW.is_active;
    v_is_sold    := NEW.is_sold;

    IF TG_OP = 'INSERT' THEN
      v_event_type := 'listing.created';
    ELSE
      -- UPDATE: classify by what changed.
      -- Priority: sold > deleted > reactivated > updated.
      -- Reactivation (is_active: false→true or is_sold: true→false) is treated
      -- as 'listing.created' so the EF busts search caches immediately,
      -- making the listing visible in results without waiting for TTL expiry.
      IF NEW.is_sold = true AND (OLD.is_sold IS DISTINCT FROM true) THEN
        v_event_type := 'listing.sold';
      ELSIF NEW.is_active = false AND (OLD.is_active IS DISTINCT FROM false) THEN
        v_event_type := 'listing.deleted';
      ELSIF (NEW.is_active = true AND OLD.is_active = false)
         OR (NEW.is_sold  = false AND OLD.is_sold  = true) THEN
        v_event_type := 'listing.created';  -- reactivated → must appear in search
      ELSE
        v_event_type := 'listing.updated';
      END IF;
    END IF;
  END IF;

  INSERT INTO search_outbox (event_type, payload)
  VALUES (
    v_event_type,
    jsonb_build_object(
      'listing_id', v_listing_id,
      'seller_id',  v_seller_id,
      'is_active',  v_is_active,
      'is_sold',    v_is_sold
    )
  );

  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$$;

-- ---------------------------------------------------------------------------
-- Trigger: listings_to_outbox
-- ---------------------------------------------------------------------------

CREATE TRIGGER listings_to_outbox
  AFTER INSERT OR UPDATE OR DELETE ON listings
  FOR EACH ROW EXECUTE FUNCTION notify_search_outbox();

-- ---------------------------------------------------------------------------
-- RPC: mark_outbox_events_processed
-- ---------------------------------------------------------------------------
-- Called by process-search-outbox EF to atomically mark a batch as done.
-- Returns the number of rows updated.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION mark_outbox_events_processed(p_ids UUID[])
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INT;
BEGIN
  UPDATE search_outbox
  SET
    processed    = true,
    processed_at = now()
  WHERE id = ANY(p_ids)
    AND processed = false;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

-- ---------------------------------------------------------------------------
-- RPC: delete_processed_outbox_events
-- ---------------------------------------------------------------------------
-- Deletes processed outbox rows older than p_older_than_days days to prevent
-- unbounded table growth and index bloat.
-- Run daily via pg_cron (see TODO below).
-- Returns the number of rows deleted.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION delete_processed_outbox_events(
  p_older_than_days INT DEFAULT 7
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INT;
BEGIN
  DELETE FROM search_outbox
  WHERE processed    = true
    AND processed_at < now() - (p_older_than_days || ' days')::INTERVAL;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

-- TODO(R-29 ops): Schedule daily outbox cleanup (pg_cron):
-- SELECT cron.schedule(
--   'delete-processed-outbox',
--   '0 3 * * *',  -- daily at 03:00 UTC
--   $$SELECT delete_processed_outbox_events(7)$$
-- );
