# Onboarding Screen

> Task: P-14 | Epic: E02 | Status: Not started | Priority: #4

---

## Screen Info

| Field | Value |
|-------|-------|
| Route | `/onboarding` |
| Auth | Not required (shown on first launch) |
| States | 3 pages + language selector + completion |
| Responsive | Compact: full-screen pages, Expanded: centered max-width 600px |
| Dark mode | Required |

## Layout

### Page 1 — Welcome + Language
- DeelMarkt logo (centered, large)
- Tagline: "De eerlijke marktplaats van Nederland" (The fair marketplace of the Netherlands)
- Language selector: NL / EN segmented control
- Illustration: friendly marketplace scene

### Page 2 — Trust
- Shield icon (large, green)
- Title: "Veilig kopen en verkopen" (Safe buying and selling)
- 3 bullet points with icons:
  - "Escrow bescherming op elke transactie" (Escrow on every transaction)
  - "Geverifieerde verkopers" (Verified sellers)
  - "Gratis retourneren" (Free returns)

### Page 3 — Get Started
- Handshake illustration
- Title: "Klaar om te beginnen?" (Ready to start?)
- "Account aanmaken" (Create account) — primary orange button
- "Ik heb al een account" (I have an account) — text link
- Page dots indicator (3 dots)

---

## Design Prompt

> Prepend [DESIGN-SYSTEM-PREAMBLE.md](../DESIGN-SYSTEM-PREAMBLE.md) before this prompt.

```
Design a 3-page onboarding flow for "DeelMarkt", a Dutch peer-to-peer
marketplace app. Show all 3 pages side by side.

PAGE 1 — WELCOME:
- DeelMarkt logo in orange (#F15A24) centered at top
- Tagline: "De eerlijke marktplaats van Nederland"
- A warm, friendly illustration of two people exchanging an item happily
  (flat/minimal style, orange + teal accent colors, no gradients)
- NL / EN language toggle (segmented control, NL active)
- 3 page dots at bottom (dot 1 active)

PAGE 2 — TRUST:
- Large green (#16A34A) shield icon at top
- Title: "Veilig kopen en verkopen" (bold, 24px)
- 3 feature rows with icons:
  🛡 "Escrow bescherming" — subtitle "Je geld is veilig tot levering"
  ✓ "Geverifieerde verkopers" — subtitle "E-mail, telefoon en iDIN verificatie"
  ↩ "Eenvoudig retourneren" — subtitle "Geen gedoe bij problemen"
- Page dots (dot 2 active)

PAGE 3 — GET STARTED:
- Handshake or gift box illustration (friendly, minimal)
- Title: "Klaar om te beginnen?"
- Large orange button: "Account aanmaken" (full width, rounded 12px, 52px height — DeelButton.large)
- Below: "Ik heb al een account" text link in primary orange
- Page dots (dot 3 active)

STYLE NOTES (in addition to preamble):
- Illustrations: flat/minimal style — use primary orange, teal (#0EA5E9),
  and neutrals. NO stock photos, NO realistic people.
- Swipe gesture implied between pages
- Immersive full-screen feel (no system bar clutter)
- Animations: subtle fade-slide (respect reduced-motion)

VARIATIONS:
1. Light mode (all 3 pages)
2. Dark mode (all 3 pages)
3. Tablet: centered card (max 500px) with more generous spacing

OUTPUT: High-fidelity UI mockup showing all 3 pages side by side,
iPhone 15 Pro frame, 1290x2796px each.
```

---

## Implementation Notes

### Flutter widgets needed
- `OnboardingScreen` — `PageView` with 3 pages
- `LanguageSwitch` (P-10) — already implemented
- `PageIndicator` — 3 dots, animated
- Uses `SharedPreferences` to mark onboarding as complete
- `ref.read(sharedPrefsProvider).setBool('onboarding_complete', true)`

### l10n keys needed
```
onboarding.tagline: "De eerlijke marktplaats van Nederland" / "The fair marketplace of the Netherlands"
onboarding.safeBuying: "Veilig kopen en verkopen" / "Safe buying and selling"
onboarding.escrowProtection: "Escrow bescherming op elke transactie" / "Escrow protection on every transaction"
onboarding.verifiedSellers: "Geverifieerde verkopers" / "Verified sellers"
onboarding.easyReturns: "Eenvoudig retourneren" / "Easy returns"
onboarding.readyToStart: "Klaar om te beginnen?" / "Ready to start?"
onboarding.createAccount: "Account aanmaken" / "Create account"
onboarding.haveAccount: "Ik heb al een account" / "I already have an account"
```
