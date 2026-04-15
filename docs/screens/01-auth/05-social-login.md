# Social Login (P-44)

| Field | Value |
|-------|-------|
| Task | P-44 |
| Epic | E02 — Auth + KYC |
| Status | Implemented (embedded pattern) |
| Route | *Embedded on `/auth/login`* — no dedicated screen |
| States | Default, Loading (per provider), Error |
| Dependencies | R-02 (Supabase Auth), R-08 (Firebase Auth) |

---

## Pattern decision (2026-04-15)

The original design proposed a dedicated `/auth/social` route with full-screen
buttons, a divider, an email-fallback link, and a terms footer.

**We ship the embedded pattern instead:** Google + Apple buttons live directly
on the login screen above the email/password form, and the full terms-footer
language is owned by `docs/screens/01-auth/03-login.md`.

**Why:**
- Fewer screens, one less navigation hop — the dominant pattern in modern
  mobile apps (Uber, Airbnb, Stripe, Supabase's own examples).
- The divider, "or", and email-fallback affordances are already present on the
  login screen itself — re-implementing them on a standalone screen would be
  duplicative.
- A dedicated screen implies social-first positioning. DeelMarkt is
  email-first (KYC + iDIN attaches to email-verified accounts); social is a
  convenience accelerator.

The designed PNG assets at
[`designs/social_login_mobile_light/`](designs/social_login_mobile_light/) and
[`designs/social_login_desktop_light/`](designs/social_login_desktop_light/)
remain as reference for button styling, spacing, and Apple HIG compliance
(black-filled Apple button, white Google button with border).

---

## Components on the login screen

1. **Google button** — `DeelButton` outline variant, white background with
   1 px border, Phosphor duotone "G" logo, label `auth.continueWithGoogle`.
2. **Apple button** — filled black (`DeelmarktColors.neutral900`), white Apple
   logo + text, 52 px height (Apple HIG). See
   [`login_social_buttons.dart`](../../../lib/features/auth/presentation/widgets/login_social_buttons.dart).
3. **Divider + "or"** — owned by `03-login.md`.
4. **Email + password form** — owned by `03-login.md`.
5. **Terms footer** — owned by `03-login.md`.

Each button shows an independent loading indicator while its OAuth sheet is
open (per-provider `SocialLoginNotifier.loadingProvider`). Cancelled sign-ins
are silent — no SnackBar. Provider-unavailable errors show
`auth.oauthUnavailable`; network errors show `error.network`.

---

## Platform flows

| Platform | Apple | Google |
|---|---|---|
| iOS | Native `ASAuthorizationController` via `sign_in_with_apple` → `signInWithIdToken(apple, idToken, nonce)` | Native `google_sign_in` → `signInWithIdToken(google, idToken, accessToken)` |
| Android | Native `sign_in_with_apple` web sheet (fallback, not HIG) → `signInWithIdToken` | Native `google_sign_in` (Play Services) → `signInWithIdToken` |
| Web | `supabase.auth.signInWithOAuth(apple)` → redirect → session via `onAuthStateChange` | Same pattern |

Nonce is generated per sign-in (32 random bytes → base64url), SHA-256-hashed
for the Apple request, and the raw value passed to Supabase so Apple's
signature can be verified.

See [`AuthRemoteDatasource.signInWithApple`](../../../lib/features/auth/data/datasources/auth_remote_datasource.dart)
and [`AuthRepositoryImpl.loginWithOAuth`](../../../lib/features/auth/data/repositories/auth_repository_impl.dart).

---

## L10n keys (in use)

```
auth.continueWithGoogle: "Doorgaan met Google" / "Continue with Google"
auth.continueWithApple:  "Doorgaan met Apple"  / "Continue with Apple"
auth.oauthUnavailable:   "Sociaal inloggen is momenteel niet beschikbaar. Log in met e-mail." / "Social login is not available right now. Please sign in with email."
```

Additional spec keys kept for future dedicated-screen variant:
```
auth.signInWith, auth.signInEmail, auth.agreeTerms, auth.terms, auth.privacy
```

---

## Accessibility

- Each button wrapped in `Semantics(button: true, label: …)` with localised
  provider name.
- Apple button enforces 52 px height; Google button inherits `DeelButton`
  large size (52 px). Both exceed the 44 × 44 minimum in CLAUDE.md §10.
- Per-button loading indicator uses `CircularProgressIndicator`; screen-reader
  announces loading state via `Semantics(enabled: !isLoading)`.
- Disabled state (while another provider is mid-flight) dims both buttons and
  ignores taps.

---

## Reference implementation

| File | Purpose |
|---|---|
| [`lib/features/auth/data/datasources/auth_remote_datasource.dart`](../../../lib/features/auth/data/datasources/auth_remote_datasource.dart) | Native OAuth + nonce, web fallback |
| [`lib/features/auth/data/repositories/auth_repository_impl.dart`](../../../lib/features/auth/data/repositories/auth_repository_impl.dart) | `loginWithOAuth` orchestrator + web auth-state listener |
| [`lib/features/auth/data/repositories/auth_error_mapper.dart`](../../../lib/features/auth/data/repositories/auth_error_mapper.dart) | Supabase error-code → `AuthResult` mapping |
| [`lib/features/auth/presentation/viewmodels/social_login_viewmodel.dart`](../../../lib/features/auth/presentation/viewmodels/social_login_viewmodel.dart) | Per-provider loading state |
| [`lib/features/auth/presentation/widgets/login_social_buttons.dart`](../../../lib/features/auth/presentation/widgets/login_social_buttons.dart) | Button visual + HIG-compliant Apple button |
| [`supabase/migrations/20260415120000_p44_oauth_user_profile_trigger.sql`](../../../supabase/migrations/20260415120000_p44_oauth_user_profile_trigger.sql) | `user_profiles` auto-provisioning |
| [`docs/operations/oauth-runbook.md`](../../operations/oauth-runbook.md) | Secret rotation, troubleshooting |
