-- Vault read helper for Edge Functions (service_role only)

CREATE OR REPLACE FUNCTION public.vault_read_secret(p_name TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  secret_value TEXT;
BEGIN
  -- Only allow service_role to call this
  IF current_setting('request.jwt.claims', true)::json ->> 'role' != 'service_role' THEN
    RAISE EXCEPTION 'Only service_role can read vault secrets';
  END IF;

  SELECT decrypted_secret INTO secret_value
  FROM vault.decrypted_secrets
  WHERE name = p_name
  LIMIT 1;

  RETURN secret_value;
END;
$$;

REVOKE ALL ON FUNCTION public.vault_read_secret FROM PUBLIC;
REVOKE ALL ON FUNCTION public.vault_read_secret FROM anon;
REVOKE ALL ON FUNCTION public.vault_read_secret FROM authenticated;
