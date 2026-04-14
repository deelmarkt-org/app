-- R-21: Storage bucket for GDPR data exports (Art. 20 GDPR).
-- The export-user-data Edge Function uploads JSON exports here and
-- returns a signed 24h URL to the authenticated user.

-- Create the bucket (idempotent via ON CONFLICT)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'user-data-exports',
  'user-data-exports',
  false,
  52428800, -- 50 MiB
  ARRAY['application/json']
)
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- RLS policies for storage.objects (bucket: user-data-exports)
-- =============================================================================

-- Users can read their own exports only.
-- Export path convention: user-data-exports/<user_id>/<timestamp>.json
CREATE POLICY storage_exports_select ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'user-data-exports'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Only service_role (Edge Function) can insert exports.
-- No INSERT policy for authenticated — the EF uses service_role client.

-- Users can delete their own exports (cleanup after download).
CREATE POLICY storage_exports_delete ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'user-data-exports'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
