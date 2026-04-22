-- ──────────────────────────────────────────────────────────────────────────
-- DeelMarkt — Local dev seed: bulk-load mode
--
-- Several migrations add AFTER INSERT triggers that call
-- `current_setting('app.settings.supabase_url')` to fire HTTP webhooks
-- (push notifications, escrow release, DLQ, reconciliation). In Supabase
-- Cloud the platform sets these GUCs; locally they don't exist, so any
-- seed INSERT that fires one of those triggers explodes with
-- "unrecognized configuration parameter".
--
-- The standard Postgres bulk-load idiom is to disable user-defined
-- trigger firing for the duration of the seed. Set it back to origin at
-- the end of 04_conversations.sql so the running app sees normal trigger
-- behaviour.
--
-- Reference:
-- https://www.postgresql.org/docs/current/runtime-config-client.html#GUC-SESSION-REPLICATION-ROLE
-- ──────────────────────────────────────────────────────────────────────────

SET session_replication_role = 'replica';
