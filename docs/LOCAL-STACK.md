# Local Stack — Dev & Manual Testing

> Run the full DeelMarkt app against a local Supabase + stubbed/shared external services. Target audience: any developer on the team who needs to run the app and click through features without a hosted staging environment.
>
> **Prerequisite:** finish [SETUP.md](SETUP.md) first (Flutter, Python, pre-commit hooks).

---

## TL;DR — one command

```bash
# macOS / Linux
bash scripts/dev-up.sh

# Windows (PowerShell)
.\scripts\dev-up.ps1
```

This orchestrates everything: starts Supabase, applies migrations + seeds, seeds the Vault (Cloudinary/Mollie/FCM from `.env` + `firebase/`), starts Edge Functions in the background, writes local `SUPABASE_URL`/`SUPABASE_ANON_PUBLIC` into `.env` (backed up first), regenerates `env.g.dart`, and launches `flutter run -d chrome`.

Flags:
- `--reset` / `-Reset` — drop DB and reapply everything from scratch.
- `-d macos` / `-Device macos` — pick a different Flutter device id.
- `--no-run` / `-NoRun` — set up but don't launch the app.

Tear down:
```bash
bash scripts/dev-down.sh            # macOS / Linux
.\scripts\dev-down.ps1               # Windows
```

If you want to understand each step (or something fails), the manual breakdown is below.

---

## What this gives you

| Layer | Runs where |
|:------|:-----------|
| Supabase (Postgres, Auth, Storage, Realtime, Edge Functions) | Local Docker via `supabase start` |
| Email (magic links, password reset) | Local Inbucket at http://localhost:54324 |
| Feature flags (Unleash) | Shared team instance (`local` environment) |
| Payments (Mollie) | Mollie test mode + per-developer ngrok tunnel |
| Image uploads (Cloudinary) | Shared team cloud, `dev-<yourname>/` folder prefix |
| Push notifications (FCM) | Shared team dev Firebase project |
| SMS OTP (Twilio) | **Disabled locally** — use email auth instead |

See [TEST-MATRIX.md](TEST-MATRIX.md) for which features are end-to-end testable this way.

---

## One-time setup (≈15 minutes)

### 1. Install the Supabase CLI + Docker

```bash
# macOS
brew install supabase/tap/supabase
# Start Docker Desktop before running anything below.

# Linux
curl -fsSL https://supabase.com/install.sh | sh

# Windows (WSL2 recommended)
scoop install supabase
```

Verify:

```bash
supabase --version   # 1.x or newer
docker ps            # must not error
```

### 2. Bootstrap the local stack

```bash
bash scripts/dev-bootstrap.sh
```

This wraps `supabase start`, applies every migration in `supabase/migrations/`, seeds a realistic dataset, and prints the URLs you need. Re-run any time to reset.

### 3. Fill in `.env`

```bash
cp .env.example .env
```

Edit `.env` with:

| Variable | Where to get it |
|:---------|:----------------|
| `SUPABASE_URL` | Printed by `dev-bootstrap.sh` (normally `http://127.0.0.1:54321`) |
| `SUPABASE_ANON_PUBLIC` | Printed by `dev-bootstrap.sh` |
| `UNLEASH_URL` / `UNLEASH_CLIENT_KEY` | Ask belengaz — shared team instance, `local` env |
| `CLOUDINARY_URL` | Ask belengaz — shared team cloud |
| `MOLLIE_TEST_API_KEY` | Ask belengaz — shared Mollie test profile |
| `SENTRY_DSN` | Leave blank for local; errors print to console |
| `UPSTASH_REDIS_REST_URL` / `_TOKEN` | Leave blank; webhook idempotency is best-effort locally |
| `PAGERDUTY_*` | Leave blank; alerts are no-op locally |
| `TWILIO_*` | Leave blank; SMS is disabled locally |

**Never commit `.env`.** `.env` is gitignored; `.env.example` is the tracked template.

### 4. Run the app

```bash
flutter pub get
flutter run
```

The app connects to the local Supabase at the URL from `.env`.

---

## Daily workflow

```bash
# Morning
bash scripts/dev-bootstrap.sh         # or: supabase start  (keeps existing data)
flutter run

# Switch branches with new migrations
supabase db reset                     # reapplies every migration from scratch

# End of day
supabase stop                         # frees ports + memory (data persists)
```

---

## Key URLs

| URL | What it is |
|:----|:-----------|
| http://127.0.0.1:54321 | Supabase API (REST + Realtime + Auth + Storage) |
| http://127.0.0.1:54323 | Supabase Studio — DB browser, SQL editor, table editor |
| http://127.0.0.1:54324 | Inbucket — see every email the app sends (signup links, password resets) |
| `postgresql://postgres:postgres@127.0.0.1:54322/postgres` | Direct DB connection (`psql`, pgAdmin, DataGrip) — standard Supabase CLI local default, not a real credential. <!-- pragma: allowlist secret --> |

---

## Testing flows that need external services

### Full-integration mode (Cloudinary + Mollie + FCM)

Edge Functions read external credentials from Supabase Vault, not from process env. The one-shot `dev-up.{sh,ps1}` script handles this automatically by calling `scripts/dev-secrets.{sh,ps1}`, which:

1. Parses `CLOUDINARY_URL` from `.env` into `CLOUDINARY_CLOUD_NAME` / `CLOUDINARY_API_KEY` / `CLOUDINARY_API_SECRET`.
2. Reads `MOLLIE_TEST_API_KEY` from `.env`.
3. Reads the Firebase admin SDK JSON from `firebase/deelmarkt-*-firebase-adminsdk-*.json` and stores it as `fcm_service_account`.
4. Writes them into the local Vault via `public.insert_vault_secret(...)`.

**Important:** the Vault is wiped on `supabase stop`. Re-run `dev-up.sh` / `dev-secrets.sh` after a restart.

### Payments (Mollie webhooks)

Mollie needs to reach *your* machine to deliver webhooks. Use ngrok:

```bash
# In a second terminal
ngrok http 54321

# Copy the https URL ngrok prints, e.g. https://abc123.ngrok-free.app
# Configure it as the webhook URL inside your Mollie test profile for this dev session.
```

Tear down the ngrok tunnel when done so stale URLs don't collect webhook deliveries.

### Push notifications

1. Ask belengaz for the dev Firebase project's `google-services.json` / `GoogleService-Info.plist`.
2. Put them in `android/app/` and `ios/Runner/` respectively (both gitignored).
3. Run on a physical device — simulators don't deliver real push.

### Feature flags (Unleash)

Set `UNLEASH_URL` + `UNLEASH_CLIENT_KEY` in `.env` pointing at the shared instance's `local` environment. Your flag states are independent of staging/prod. Ask belengaz to add you as a member before first run.

If the Unleash instance is unreachable, the client's fallback returns `false` for every flag — you'll see the "flag OFF" path. That's fine for most local testing.

---

## Troubleshooting

| Symptom | Fix |
|:--------|:----|
| `supabase start` hangs | `docker ps`; if empty, start Docker Desktop. If ports are busy, `supabase stop` then retry. |
| `column "X" does not exist` after pulling | `supabase db reset` — reapplies all migrations. |
| Auth works but emails don't arrive | Open http://localhost:54324 — all emails land in Inbucket, not your real inbox. |
| App can't connect: `Connection refused 54321` | `supabase start` again. Local stack doesn't auto-restart on reboot. |
| Cloudinary upload fails locally | Confirm `CLOUDINARY_URL` in `.env` matches the shared team cloud (ask belengaz). |
| `flutter run` but realtime updates don't stream | Supabase Realtime runs on port 54321 — no extra config. If broken, check `supabase status`. |

---

## When to graduate to hosted staging

Local-only is sufficient for ~70% of manual testing (see [TEST-MATRIX.md](TEST-MATRIX.md)). You need a hosted staging Supabase project when you're:

- QA'ing multi-user flows simultaneously (two real accounts on two phones)
- Verifying signed release builds before a TestFlight / internal-testing cut
- Getting legal sign-off for a >10% Unleash rollout of a trust signal

That work is tracked on [MANUAL-TASKS-BELENGAZ.md](MANUAL-TASKS-BELENGAZ.md) and follows Apple/Google developer-account registration.

---

## Reference

- [supabase/config.toml](../supabase/config.toml) — local stack ports and auth config.
- [supabase/migrations/](../supabase/migrations/) — source of truth for the DB schema.
- [scripts/dev-bootstrap.sh](../scripts/dev-bootstrap.sh) — the script this doc assumes.
- [docs/TEST-MATRIX.md](TEST-MATRIX.md) — what is / isn't testable locally.
