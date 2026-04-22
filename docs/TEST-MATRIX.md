# Test Matrix — What Can / Can't Be Tested Locally

> Reference table for manual QA. Maps each feature area to whether it's fully testable against the local stack from [LOCAL-STACK.md](LOCAL-STACK.md), testable with workarounds, or requires hosted staging.
>
> Keep this up to date as new features land. If you add a feature that can't be fully tested locally, add a row.

**Legend**

| Mark | Meaning |
|:----:|:--------|
| ✅ | Fully testable on local stack out of the box |
| 🟡 | Testable locally with a documented workaround (ngrok, shared team credentials, etc.) |
| 🔴 | Requires hosted staging or real-device / real-store testing |

---

## Auth & Identity (E02)

| Flow | Local | Notes |
|:-----|:-----:|:------|
| Email sign-up + magic link | ✅ | Emails land in [Inbucket](http://localhost:54324). |
| Password reset | ✅ | Inbucket. |
| Sign-in / sign-out | ✅ | |
| Email change (double confirm) | ✅ | Both old + new address emails in Inbucket. |
| Session persistence across app restarts | ✅ | |
| Rate-limited login (5 failed attempts) | ✅ | `supabase/config.toml` `[auth.rate_limit]` applies locally. |
| SMS / phone OTP | 🔴 | Twilio disabled locally. Use email auth or hosted staging. |
| KYC L0 → L2 upgrade | ✅ | Trigger via Supabase Studio SQL editor: `UPDATE user_profiles SET kyc_level = 'level2' WHERE id = '<uid>'`. |
| Social login (Apple, Google) | 🔴 | Requires signed release build + real OAuth apps. |

## Listings (E01)

| Flow | Local | Notes |
|:-----|:-----:|:------|
| Create listing (all steps) | 🟡 | Images fail without Cloudinary creds. See LOCAL-STACK.md §Cloudinary. |
| Edit / delete listing | ✅ | |
| Quality score recompute | ✅ | Runs server-side on update. |
| Escrow-eligibility cascade | ✅ | See [docs/runbooks/gh59-escrow-staging-verification.md](runbooks/gh59-escrow-staging-verification.md) — Gate 0–3 run verbatim against local. |
| Favourites add/remove | ✅ | |
| Search + filters | ✅ | |
| Nearby (geo) listings | ✅ | PostGIS runs in the local Postgres. |
| Image upload retry on 429 | 🟡 | Local Cloudinary unlikely to rate-limit; force via DTO fake or use staging. |

## Payments & Escrow (E03)

| Flow | Local | Notes |
|:-----|:-----:|:------|
| Checkout intent creation | ✅ | Mollie test key hits Mollie's test sandbox. |
| Mollie payment webhook delivery | 🟡 | Needs ngrok tunnel to reach your local Edge Function. See LOCAL-STACK.md §Payments. |
| Escrow release on delivery confirmation | ✅ | Assumes webhook reached you. |
| Refund path | 🟡 | Same webhook caveat. |
| Payment idempotency (Upstash Redis NX) | 🟡 | Upstash creds optional locally → best-effort idempotency; good-enough for click-through QA, insufficient for concurrency testing. |
| DLQ + PagerDuty alert on 5th retry | 🔴 | No PagerDuty locally. Hosted staging only. |

## Messaging / Chat (E04)

| Flow | Local | Notes |
|:-----|:-----:|:------|
| Send text message | ✅ | |
| Realtime delivery between two users | 🟡 | Works locally, but needs two emulators / devices connecting to the same `supabase start`. Run from the same machine or expose via LAN IP. |
| Offer / counter-offer | ✅ | |
| Read receipts | ✅ | |
| Response-time scoring | ✅ | |

## Shipping & Logistics (E05)

| Flow | Local | Notes |
|:-----|:-----:|:------|
| Address validation (Dutch postcode) | ✅ | |
| Shipping label creation | 🟡 | Provider sandbox credentials required — ask belengaz. |
| QR code rendering | ✅ | |
| Delivery status webhook | 🟡 | Provider → ngrok, same pattern as Mollie. |

## Trust & Moderation (E06)

| Flow | Local | Notes |
|:-----|:-----:|:------|
| Report listing / user | ✅ | |
| Admin moderation queue | ✅ | Promote your dev user via SQL: `UPDATE user_profiles SET role = 'admin'`. |
| Scam signal triggers | ✅ | |
| Audit log writes | ✅ | `audit_logs` table. |

## Infrastructure & Feature Flags (E07)

| Flow | Local | Notes |
|:-----|:-----:|:------|
| Unleash flag evaluation | 🟡 | Requires shared team Unleash instance — ask belengaz. Flag fallback is `false` if unreachable. |
| Remote config updates | 🟡 | Same as Unleash. |
| Sentry error reporting | 🔴 | Leave `SENTRY_DSN` blank locally; errors print to console. |
| Crashlytics | 🔴 | Requires Firebase + signed build on real device. |

## Accessibility & UI polish

| Flow | Local | Notes |
|:-----|:-----:|:------|
| Dark / light theme switch | ✅ | |
| NL / EN locale switch | ✅ | |
| Screen reader (VoiceOver / TalkBack) | 🟡 | Works locally on a real device; simulator support is patchy. |
| Reduce-motion behaviour | ✅ | Toggle in OS settings. |
| Touch-target ≥ 44×44 audit | ✅ | Flutter Inspector. |

---

## Requires hosted staging (can't be faked locally)

These need to wait until `deelmarkt-staging` Supabase project + Apple/Google developer accounts + Codemagic signing exist:

- **Real push notifications** on iOS (APNs requires a provisioning profile).
- **Signed release builds** — TestFlight, Play Internal Testing.
- **Multi-user concurrent load** at realistic scale (>10 simultaneous users).
- **Canary rollout telemetry** — checkout 409 rate, badge-accuracy Sentry events, cascade-trigger p99 latency.
- **Legal sign-off gates** — anything in `FEATURE-FLAGS.md` that requires evidence from a live non-prod environment (e.g. trust-signal flags before >10% rollout).
- **App store screenshot pipeline** validation (fastlane).
- **Firebase Remote Config** with realistic client population.

---

## Onboarding a new dev (quick checklist)

1. Read [SETUP.md](SETUP.md) — install Flutter, Python, pre-commit hooks.
2. Read [LOCAL-STACK.md](LOCAL-STACK.md) — install Supabase CLI + Docker.
3. Run `bash scripts/dev-bootstrap.sh`.
4. Fill `.env` from the values the bootstrap prints + ask belengaz for the shared-service credentials.
5. `flutter run` — should land on the home screen.
6. Skim this matrix and work through the ✅ rows once to confirm your stack is healthy.
7. For 🟡 rows, follow the link / note when you need that feature.
8. Flag any new feature you add that falls into 🔴 so it gets added here.
