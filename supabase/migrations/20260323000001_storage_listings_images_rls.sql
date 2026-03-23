-- R-05: Storage RLS for listings-images bucket
-- Upload pipeline: Storage → Edge Function (EXIF strip + resize) → Cloudinary CDN
-- End users fetch images via Cloudinary, not directly from Storage.

-- Create the bucket if it doesn't exist (idempotent via INSERT … ON CONFLICT)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'listings-images',
  'listings-images',
  false,
  15728640, -- 15 MiB (COMPLIANCE.md: max 15 MB/image)
  ARRAY['image/png', 'image/jpeg', 'image/webp', 'image/heic']
)
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- RLS policies for storage.objects (bucket: listings-images)
-- =============================================================================

-- Authenticated users can upload images to their own folder: listings-images/<user_id>/*
CREATE POLICY storage_listings_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'listings-images'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Authenticated users can update/replace their own images
CREATE POLICY storage_listings_update ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'listings-images'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Authenticated users can delete their own images
CREATE POLICY storage_listings_delete ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'listings-images'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Authenticated users can read listing images (Edge Functions use service_role)
-- No anon access: bucket is private, images served via Cloudinary CDN
CREATE POLICY storage_listings_select ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'listings-images');
