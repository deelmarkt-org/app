-- B-13: Store Mollie API keys in Supabase Vault
-- Wrapper function to insert secrets via PostgREST (vault schema not exposed)

CREATE OR REPLACE FUNCTION public.insert_vault_secret(
  p_name TEXT,
  p_secret TEXT,
  p_description TEXT DEFAULT ''
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  secret_id UUID;
BEGIN
  -- Only allow service_role to call this
  IF current_setting('request.jwt.claims', true)::json ->> 'role' != 'service_role' THEN
    RAISE EXCEPTION 'Only service_role can manage vault secrets';
  END IF;

  SELECT vault.create_secret(p_secret, p_name, p_description) INTO secret_id;
  RETURN secret_id;
END;
$$;

-- Revoke public access, only service_role via PostgREST
REVOKE ALL ON FUNCTION public.insert_vault_secret FROM PUBLIC;
REVOKE ALL ON FUNCTION public.insert_vault_secret FROM anon;
REVOKE ALL ON FUNCTION public.insert_vault_secret FROM authenticated;
