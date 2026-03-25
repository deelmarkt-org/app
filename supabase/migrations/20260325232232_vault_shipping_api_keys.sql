-- B-25/B-26/B-28: Store shipping API keys in Supabase Vault.
-- Keys are inserted via the insert_vault_secret RPC (service_role only).
-- Edge Functions read via vault_read_secret RPC per §9.
--
-- Run manually after deployment:
--   SELECT insert_vault_secret('ECTARO_API_KEY', '<key>');
--   SELECT insert_vault_secret('POSTNL_API_KEY', '<key>');

-- Nothing to create here — Vault functions (vault_read_secret, insert_vault_secret)
-- were created in 20260321232641_transactions_ledger_webhook_events.sql.
-- This migration is a documentation placeholder for the shipping API keys.
SELECT 1;
