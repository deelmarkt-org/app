-- Atomic toggle_favourite RPC: replaces 3 round-trips with a single call.
-- Returns the new is_favourited state as boolean.
-- Addresses gemini-code-assist finding on supabase_listing_repository.dart:196
CREATE OR REPLACE FUNCTION toggle_favourite(p_listing_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_existed BOOLEAN;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Try to delete; if a row was removed, it was favourited before.
  DELETE FROM favourites
    WHERE user_id = v_user_id AND listing_id = p_listing_id;

  v_existed := FOUND;

  IF NOT v_existed THEN
    INSERT INTO favourites (user_id, listing_id)
      VALUES (v_user_id, p_listing_id);
  END IF;

  -- Return new state: true = now favourited, false = unfavourited
  RETURN NOT v_existed;
END;
$$;

-- Grant execute to authenticated users only
GRANT EXECUTE ON FUNCTION toggle_favourite(UUID) TO authenticated;
