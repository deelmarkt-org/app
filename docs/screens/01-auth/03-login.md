# Login Screen

> Task: P-16 | Epic: E02 | Status: In progress | Priority: #5

---

## Screen Info

| Field | Value |
|-------|-------|
| Route | `/login` |
| Auth | Not required |
| States | Form, Biometric prompt, Loading, Error, Success |
| Responsive | Compact: full-screen, Expanded: centered card max 480px |
| Dark mode | Required |

## Layout

1. **DeelMarkt logo** (centered, medium size)
2. **Welcome text** — "Welkom terug" (Welcome back)
3. **Social login** — Google + Apple buttons (same as registration)
4. **Divider** — "of"
5. **Email field** — "E-mailadres"
6. **Password field** — show/hide toggle
7. **Forgot password link** — "Wachtwoord vergeten?" (right-aligned)
8. **Login button** — "Inloggen" (primary orange, full-width)
9. **Biometric prompt** — Face ID / fingerprint icon below login button (if available)
10. **Register link** — "Nieuw bij DeelMarkt? Account aanmaken" (bottom)

---

## Design Prompt

> Prepend [DESIGN-SYSTEM-PREAMBLE.md](../DESIGN-SYSTEM-PREAMBLE.md) before this prompt.

```
SCREEN-SPECIFIC DESIGN: Login Screen

LAYOUT:
- DeelMarkt logo centered at top (orange, medium size)
- "Welkom terug" (Welcome back) in h1 semibold, centered
- "Doorgaan met Google" + "Doorgaan met Apple" outlined buttons
- "of" divider
- Email input field
- Password input with show/hide toggle
- "Wachtwoord vergeten?" right-aligned link (orange text)
- "Inloggen" large orange primary button
- Face ID icon (subtle, centered below button) — biometric option
- "Nieuw bij DeelMarkt? Account aanmaken" link at bottom

CONTENT: Clean, minimal — the screen should feel fast to complete.

VARIATIONS: Light, Dark, Expanded (centered card 480px on grey background),
Error state (wrong password — red border + "Onjuist wachtwoord" message),
Biometric prompt (system Face ID dialog overlaid)
```

---

## l10n keys
```
auth.welcomeBack: "Welkom terug" / "Welcome back"
auth.welcomeSubtitle: "Log in om verder te gaan" / "Log in to continue"
auth.forgotPassword: "Wachtwoord vergeten?" / "Forgot password?"  # pragma: allowlist secret
auth.forgotPasswordComingSoon: "Binnenkort beschikbaar" / "Coming soon"  # pragma: allowlist secret
auth.logIn: "Inloggen" / "Log in"
auth.useFaceId: "Inloggen met Face ID" / "Log in with Face ID"
auth.useFingerprint: "Inloggen met vingerafdruk" / "Log in with fingerprint"
auth.biometricReason: "Log in op DeelMarkt" / "Log in to DeelMarkt"
auth.invalidCredentials: "Onjuist e-mailadres of wachtwoord" / "Incorrect email or password"  # pragma: allowlist secret
auth.newToDeelMarkt: "Nieuw bij DeelMarkt?" / "New to DeelMarkt?"
auth.continueWithGoogle: "Doorgaan met Google" / "Continue with Google"
auth.continueWithApple: "Doorgaan met Apple" / "Continue with Apple"
auth.errorBiometricFailed: "Biometrische verificatie mislukt" / "Biometric verification failed"
auth.errorRateLimited: "Te veel pogingen. Probeer opnieuw over {0} minuten" / "Too many attempts. Try again in {0} minutes"
auth.errorSessionExpired: "Sessie verlopen. Log opnieuw in" / "Session expired. Please log in again"
```

### Notes
- `auth.invalidCredentials` replaces the spec's original `auth.wrongPassword` key.
  This is intentional (security fix H-2): a generic message prevents user enumeration.
- `auth.useFaceId` / `auth.useFingerprint` replace `auth.biometricLogin` to provide
  device-specific labels with matching icons.
