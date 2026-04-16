-- P-44: Auto-create user_profiles row on first OAuth sign-in.
--
-- When a user registers via Google or Apple Sign-In, Supabase Auth creates
-- the auth.users row automatically but the app's user_profiles table is left
-- empty. This trigger bridges the gap so the rest of the app can always
-- assume a user_profiles row exists for any authenticated user.
--
-- For email/password registration the trigger fires too — ON CONFLICT DO
-- NOTHING ensures the manually-created row (with consent timestamps stored
-- in raw_user_meta_data) is never overwritten.
--
-- display_name priority:
--   1. raw_user_meta_data->>'full_name'  (Google, Apple with name consent)
--   2. raw_user_meta_data->>'name'       (some providers use 'name')
--   3. local part of email               (fallback — always present)
--
-- avatar_url is validated:
--   - must start with https:// (reject http://, javascript:, data:, file:)
--   - max length 500 chars
--   otherwise stored as NULL.

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _display_name TEXT;
  _raw_avatar   TEXT;
  _avatar_url   TEXT;
BEGIN
  _display_name := COALESCE(
    NULLIF(TRIM(NEW.raw_user_meta_data->>'full_name'), ''),
    NULLIF(TRIM(NEW.raw_user_meta_data->>'name'), ''),
    SPLIT_PART(NEW.email, '@', 1)
  );

  _raw_avatar := NULLIF(TRIM(COALESCE(
    NEW.raw_user_meta_data->>'avatar_url',
    NEW.raw_user_meta_data->>'picture'
  )), '');

  IF _raw_avatar IS NOT NULL
     AND LENGTH(_raw_avatar) <= 500
     AND _raw_avatar ~* '^https://'
  THEN
    _avatar_url := _raw_avatar;
  ELSE
    _avatar_url := NULL;
  END IF;

  INSERT INTO public.user_profiles (id, display_name, avatar_url)
  VALUES (NEW.id, _display_name, _avatar_url)
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- Drop existing trigger if present (idempotent migration).
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_auth_user();

-- Grant execute to supabase_auth_admin (the role Supabase Auth uses internally).
GRANT EXECUTE ON FUNCTION public.handle_new_auth_user() TO supabase_auth_admin;
