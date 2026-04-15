# OAuth Run-book (P-44)

Operational guide for rotating Google + Apple Sign-In credentials, verifying redirect configuration, and troubleshooting production OAuth failures.

---

## 1. Secret rotation

Secrets are stored in **Supabase Dashboard → Project Settings → Edge Functions → Secrets** (for runtime env) and in **Authentication → Providers** (for OAuth provider config). They are referenced from `supabase/config.toml` via `env(...)` substitution:

| Env var | Source | Rotate when |
|---|---|---|
| `SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID` | Google Cloud Console → OAuth 2.0 Client IDs → Web client | Leaked / engineer offboarded |
| `SUPABASE_AUTH_EXTERNAL_GOOGLE_SECRET` | same | Quarterly; on leak |
| `SUPABASE_AUTH_EXTERNAL_APPLE_CLIENT_ID` | Apple Developer → Certificates, IDs & Profiles → Services ID (`com.deelmarkt.signin`) | Never unless revoked |
| `SUPABASE_AUTH_EXTERNAL_APPLE_SECRET` | Generated JWT signed with Apple p8 key (6-month max validity) | Every 5 months |

### Rotation procedure (Google)

1. Google Cloud Console → APIs & Services → Credentials → the OAuth client used.
2. **Add new secret** (do not delete old yet).
3. Update Supabase Dashboard → Auth → Providers → Google with the new secret. Save.
4. Verify with a staging OAuth sign-in.
5. Delete old secret in Google Cloud Console (≥ 24 h after step 3 so in-flight sessions aren't invalidated).

### Rotation procedure (Apple)

Apple client secrets are JWTs signed with a `.p8` key, max 6-month lifetime. Generate via `scripts/generate_apple_client_secret.ts` (TODO) or manually:

```bash
# one-liner using jose CLI (`npm i -g jose-cli`)
jose sign \
  --alg ES256 \
  --key ./AuthKey_XXXXX.p8 \
  --kid XXXXX \
  --iss <TEAM_ID> \
  --sub com.deelmarkt.signin \
  --aud https://appleid.apple.com \
  --exp "$(date -u -d '+5 months' +%s)" \
  --iat "$(date -u +%s)"
```

Update `SUPABASE_AUTH_EXTERNAL_APPLE_SECRET` in Supabase Dashboard.

---

## 2. Redirect URL allowlist

Configured in `supabase/config.toml → [auth] → additional_redirect_urls`:

- `io.supabase.deelmarkt://login-callback` — native mobile deep-link (Android intent-filter + iOS `CFBundleURLTypes`)
- `https://deelmarkt.com/auth/callback` — web flow + Android App Links
- `https://127.0.0.1:3000` — local dev

**Any redirect URL not on this list is rejected by Supabase Auth.** When adding a new environment (staging, preview), append the URL and redeploy config.

### Android App Links verification

Cloudflare serves `/.well-known/assetlinks.json` at `deelmarkt.com`. It must include the app's SHA-256 fingerprint:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.deelmarkt.app",
    "sha256_cert_fingerprints": ["<SHA256 from Play Console App Signing>"]
  }
}]
```

Verify with:

```bash
adb shell pm verify-app-links --re-verify com.deelmarkt.app
adb shell pm get-app-links com.deelmarkt.app
# expected: deelmarkt.com  verified
```

---

## 3. Provider enablement checklist

Before enabling a provider in `config.toml`:

- [ ] Migration `20260415120000_p44_oauth_user_profile_trigger.sql` applied on the target environment (`supabase db push` or `check_deployments.sh --deploy`)
- [ ] Client ID + secret added to Supabase Dashboard
- [ ] Redirect URLs match `additional_redirect_urls` on both sides (Supabase + provider console)
- [ ] SHA-256 fingerprint in Google Cloud Console matches the Play signing key (Android)
- [ ] Bundle ID in Apple Services ID matches `ios/Runner/Info.plist` `CFBundleIdentifier`
- [ ] Smoke test: sign in → verify `user_profiles` row created → sign out → sign back in (ON CONFLICT DO NOTHING works)

---

## 4. Troubleshooting

| Symptom | Likely cause | Remedy |
|---|---|---|
| "provider is disabled" in app | `config.toml` changed but not pushed to linked project | `supabase db push` + redeploy |
| Redirect loop / `redirect_uri_mismatch` | Callback URL missing from allowlist OR provider console | Compare both, append to `additional_redirect_urls` |
| Sign-in succeeds but `user_profiles.id` missing | Trigger not applied | Re-run migration; check `pg_trigger` |
| Apple returns `invalid_client` | Client secret JWT expired (>6 months) | Regenerate per §1 |
| Android deep-link opens browser, not app | Intent-filter missing or `autoVerify` failed | Check `AndroidManifest.xml`, re-verify assetlinks |
| "Signed in" event never fires on mobile | Deep-link not registered with Flutter engine | Verify `initial_url_handler` / `app_links` wiring |
| Coverage of OAuth flow drops | Mock not seeded in test | See `test/features/auth/presentation/viewmodels/social_login_viewmodel_test.dart` |

---

## 5. Monitoring

- Supabase Auth logs: Dashboard → Logs → Auth → filter `provider=google` / `provider=apple`
- Sentry tag `oauth.provider` on `AuthFailureOAuthUnavailable` / `AuthFailureNetworkError`
- Daily Grafana panel: OAuth sign-in success rate per provider (target ≥ 98 %)

---

## 6. Rollback

If a provider misbehaves in production:

1. Supabase Dashboard → Auth → Providers → toggle **off** (instant, no redeploy).
2. Flutter client catches `AuthFailureOAuthUnavailable` and shows `auth.oauthUnavailable` SnackBar — users gracefully fall back to email login.
3. No database rollback required — trigger is idempotent and does not modify existing rows.
