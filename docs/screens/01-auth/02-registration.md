# Registration Screen

> Task: P-15 | Epic: E02 | Status: Not started | Priority: #5

---

## Screen Info

| Field | Value |
|-------|-------|
| Route | `/register` |
| Auth | Not required |
| States | Form, OTP input, Success, Error, Loading |
| Responsive | Compact: full-screen, Expanded: centered card max 480px |
| Dark mode | Required |

## Layout

1. **Back arrow** + "Account aanmaken" header
2. **Social login buttons** — "Doorgaan met Google" / "Doorgaan met Apple" (full-width, outlined)
3. **Divider** — "of" (or) centered
4. **Email field** — label "E-mailadres", validation, error state
5. **Phone field** — label "Telefoonnummer", +31 prefix, Dutch format
6. **Password field** — label "Wachtwoord", strength indicator, show/hide toggle
7. **Two consent checkboxes** (GDPR Art. 7 — separate granular consent required):
   - Checkbox A: "Ik ga akkoord met de [Algemene voorwaarden]"
   - Checkbox B: "Ik ga akkoord met het [Privacybeleid]"
   - Both must be checked before submit is enabled
   - Links open in external browser (`LaunchMode.externalApplication`)
8. **Submit button** — "Account aanmaken" (primary orange, full-width)
9. **Login link** — "Al een account? Inloggen" (bottom)

### OTP Verification (after submit)
- 6-digit code input (large, spaced boxes)
- "Code verzonden naar +31 6 •••• 1234"
- "Opnieuw versturen" (Resend) countdown timer
- Auto-submit on 6th digit

---

## Design Prompt

> Prepend [DESIGN-SYSTEM-PREAMBLE.md](../DESIGN-SYSTEM-PREAMBLE.md) before this prompt.

```
SCREEN-SPECIFIC DESIGN: Registration Screen + OTP Verification

Show TWO states side by side:

STATE 1 — REGISTRATION FORM:
- Back arrow + "Account aanmaken" title
- "Doorgaan met Google" button (outlined, Google logo left)
- "Doorgaan met Apple" button (outlined, Apple logo left)
- "of" divider line
- Email input: "E-mailadres" label
- Phone input: "+31" prefix chip + "6 12345678" placeholder
- Password input: show/hide toggle, strength bar below (red→amber→green)
- Checkbox: "Ik ga akkoord met de Algemene voorwaarden en Privacybeleid"
  (links in orange)
- "Account aanmaken" large orange button
- "Al een account? Inloggen" link at bottom

STATE 2 — OTP VERIFICATION:
- Back arrow + "Verificatie" title
- Illustration: phone with checkmark
- "Voer de code in" (Enter the code)
- "Code verzonden naar +31 6 •••• 1234"
- 6 large digit boxes (56x56px each, 12px gap)
- "Opnieuw versturen in 0:45" countdown
- Auto-verification after 6th digit

VARIATIONS: Light, Dark, Expanded (centered card), Error state (red border
on invalid fields + error message below), Loading (button shows spinner)
```

---

## l10n keys
```
auth.createAccount: "Account aanmaken" / "Create account"
auth.continueWithGoogle: "Doorgaan met Google" / "Continue with Google"
auth.continueWithApple: "Doorgaan met Apple" / "Continue with Apple"
auth.or: "of" / "or"
auth.email: "E-mailadres" / "Email address"
auth.phone: "Telefoonnummer" / "Phone number"
auth.password: "Wachtwoord" / "Password"  # pragma: allowlist secret
auth.terms_agree_prefix: "Ik ga akkoord met de " / "I agree to the "
auth.terms_link: "Algemene voorwaarden" / "Terms and conditions"
auth.privacy_agree_prefix: "Ik ga akkoord met het " / "I agree to the "
auth.privacy_link: "Privacybeleid" / "Privacy policy"
auth.haveAccount: "Al een account?" / "Already have an account?"
auth.login: "Inloggen" / "Log in"
auth.verification: "Verificatie" / "Verification"
auth.enterCode: "Voer de code in" / "Enter the code"
auth.codeSentTo: "Code verzonden naar {phone}" / "Code sent to {phone}"
auth.resendIn: "Opnieuw versturen in {time}" / "Resend in {time}"
auth.resend: "Opnieuw versturen" / "Resend"
```
