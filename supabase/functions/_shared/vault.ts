import { createClient } from "jsr:@supabase/supabase-js@2";

/**
 * Read a secret from Supabase Vault via the vault_read_secret RPC.
 * Throws if the secret is not found — never returns null.
 */
export async function getVaultSecret(
  supabase: ReturnType<typeof createClient>,
  secretName: string,
): Promise<string> {
  const { data, error } = await supabase.rpc("vault_read_secret", {
    p_name: secretName,
  });
  if (error || !data) {
    throw new Error(
      `Failed to read vault secret '${secretName}': ${error?.message}`,
    );
  }
  return data;
}
