# Social Login Screen (P-44)

| Field | Value |
|-------|-------|
| Task | P-44 |
| Epic | E02 — Auth + KYC |
| Status | Not started |
| Route | `/auth/social` |
| States | Default, Loading (per provider), Error |
| Dependencies | R-02 (Supabase Auth), R-08 (Firebase Auth) |

---

## Layout

1. **Back arrow** — returns to login screen
2. **Heading** — "Inloggen met" / "Sign in with"
3. **Social provider buttons** (full width, stacked, 52px height each):
   - Google — white background, Google "G" logo, "Doorgaan met Google"
   - Apple — black background, Apple logo, "Doorgaan met Apple"
   - (Future: Facebook, DigiD)
4. **Divider** — "of" / "or" centered divider line
5. **Email fallback link** — "Inloggen met e-mail" / "Sign in with email" text link
6. **Terms footer** — "Door in te loggen ga je akkoord met onze Voorwaarden en Privacybeleid"

---

## Design Prompt

```
SCREEN: Social Login — DeelMarkt Dutch P2P marketplace app

LAYOUT (mobile 390x844):
- Status bar (dark text on light background)
- Top: back arrow (44x44 tap target)
- 48px top spacing
- Heading: "Inloggen met" — 24px SemiBold, #1A1A2E
- 32px spacing
- Google button: full width, white #FFFFFF background, 1px #E5E5E5 border,
  rounded 12px, 52px height, Google "G" logo 24px + "Doorgaan met Google"
  16px Medium #1A1A2E, centered
- 12px spacing
- Apple button: full width, black #1A1A2E background,
  rounded 12px, 52px height, Apple logo 24px white + "Doorgaan met Apple"
  16px Medium #FFFFFF, centered
- 24px spacing
- Centered divider: thin line #E5E5E5 with "of" label in 14px Regular
  #6B7280 on white background interrupting the line
- 24px spacing
- Email link: "Inloggen met e-mail" 16px Medium #FF6B00 centered
- Flex spacer
- Terms footer: "Door in te loggen ga je akkoord met onze" 12px Regular
  #6B7280, "Voorwaarden" and "Privacybeleid" as #FF6B00 links

LAYOUT (web >=1024px):
- Centered card (480px max), white background, rounded 16px, subtle shadow
- Same content layout inside the card
- Background: neutral50 #F9FAFB

STYLE: Clean, minimal, trust-focused. White background, generous spacing.
Social buttons feel native to each platform (Google Material, Apple HIG).

ACCESSIBILITY: All buttons 52px height (exceeds 44px minimum), focus rings
visible, button labels include provider name for screen readers.
```

---

## L10n Keys

```
auth.signInWith: "Inloggen met" / "Sign in with"
auth.continueGoogle: "Doorgaan met Google" / "Continue with Google"
auth.continueApple: "Doorgaan met Apple" / "Continue with Apple"
auth.or: "of" / "or"
auth.signInEmail: "Inloggen met e-mail" / "Sign in with email"
auth.agreeTerms: "Door in te loggen ga je akkoord met onze" / "By signing in you agree to our"
auth.terms: "Voorwaarden" / "Terms"
auth.privacy: "Privacybeleid" / "Privacy Policy"
```
