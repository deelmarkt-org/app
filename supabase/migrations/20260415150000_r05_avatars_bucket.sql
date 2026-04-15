-- R-05b: Storage bucket for user avatar images (Issue #148).
--
-- The SupabaseAvatarUploadService uploads profile pictures here and
-- returns a public URL via storage.getPublicUrl().  Bucket is therefore
-- PUBLIC — avatars are displayed to all users on profile and listing cards.
--
-- Path convention: avatars/<userId>/<timestamp>.<ext>
-- Matches SupabaseAvatarUploadService storagePath construction.
--
-- File limits:
--   • Max size: 15 MiB (matches service-side maxFileSizeBytes)
--   • Allowed MIME: PNG, JPEG, WebP, HEIC (matches _allowedExtensions)
--
-- RLS summary:
--   • INSERT  — authenticated, own folder only (prevent overwriting others)
--   • UPDATE  — authenticated, own folder only (upsert / replace)
--   • DELETE  — authenticated, own folder only
--   • SELECT  — public (bucket is public; policy is belt-and-suspenders)
--
-- Reference: lib/features/profile/data/services/supabase_avatar_upload_service.dart

-- Create the bucket (idempotent via ON CONFLICT)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,         -- public: getPublicUrl() is used by the Flutter service
  15728640,     -- 15 MiB
  ARRAY['image/png', 'image/jpeg', 'image/webp', 'image/heic']
)
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- RLS policies for storage.objects (bucket: avatars)
-- =============================================================================

-- Authenticated users can upload avatars to their own folder only.
CREATE POLICY storage_avatars_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Authenticated users can replace (upsert) their own avatar.
CREATE POLICY storage_avatars_update ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Authenticated users can delete their own avatar (e.g. account reset).
CREATE POLICY storage_avatars_delete ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Anyone can read avatars — bucket is public, profiles are visible to all.
CREATE POLICY storage_avatars_select ON storage.objects
  FOR SELECT TO public
  USING (bucket_id = 'avatars');
