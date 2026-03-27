# Mollie Checkout Screen (Reference — Implemented)

> Task: B-14 | Epic: E03 | Status: **Implemented** | File: `lib/features/transaction/presentation/screens/mollie_checkout_screen.dart`

---

## Screen Info

| Field | Value |
|-------|-------|
| Route | Modal / push (not a named route — opened programmatically) |
| Auth | Required |
| States | Loading (WebView loading overlay), WebView active, Error, Completed (pops), Cancelled (pops) |
| Responsive | Mobile only (WebView — not applicable to web/desktop) |
| Dark mode | Partial — via Theme, but WebView content is Mollie-controlled |

## Current Layout (as implemented)

1. **AppBar** — "Betalen met iDEAL" (payment.payWithIdeal), X close button (left) → cancels
2. **WebView** — full-screen Mollie iDEAL checkout, JavaScript enabled for bank selection + 3DS
3. **Loading overlay** — white semi-transparent + CircularProgressIndicator + "Betaling verwerken..." (payment.processing)
4. **Error state** — warning icon (48px, error red) + "Betaling mislukt" + "Netwerkfout" + Retry button (secondary) + Cancel button (ghost)
5. **Navigation guard** — only allows Mollie domains + HTTPS bank redirects. Redirect URL detection pops with `completed` result.

## Design Prompt (reference)

> Prepend [DESIGN-SYSTEM-PREAMBLE.md](../DESIGN-SYSTEM-PREAMBLE.md) before this prompt.

```
SCREEN-SPECIFIC DESIGN: Mollie Checkout Screen (REFERENCE — already built)

This is a WebView wrapper — the payment UI is controlled by Mollie.
Design only the app chrome around it.

LAYOUT:
- AppBar: "Betalen met iDEAL" title, X close button (left, 44x44)
- Full-screen WebView showing Mollie iDEAL bank selector
  (show a realistic iDEAL bank selection page mockup inside the WebView)
- Loading overlay: white at 80% opacity over WebView,
  CircularProgressIndicator.adaptive centered,
  "Betaling verwerken..." text below (body-md)

ERROR STATE:
- Centered column: warning-circle icon (48px, error #E53E3E)
- "Betaling mislukt" heading (titleMedium — NOTE: should be headlineMedium)
- "Netwerkfout — probeer opnieuw" body text (neutral-500)
- "Opnieuw proberen" secondary button (#1E4F7A) with refresh icon
- "Annuleren" ghost button below

VARIATIONS: Loading overlay active, Error state, Normal WebView active
```

## Implementation Audit

| Check | Status | Notes |
|-------|--------|-------|
| Colors from `DeelmarktColors` | PASS | `error`, `white`, `neutral500` |
| Typography from theme | WARN | Error heading uses `titleMedium` — should be `headlineMedium` per tokens.md |
| Spacing from `Spacing` | PASS | `s2`, `s3`, `s4`, `s6` |
| l10n keys | PASS | All text via `.tr()` |
| Semantics | PASS | Loading overlay + error state both have `Semantics(liveRegion: true)` |
| Dark mode | PARTIAL | Loading overlay uses hardcoded `DeelmarktColors.white` — no isDark check |
| Security | PASS | URL validation, trusted hosts whitelist, HTTPS-only navigation |
| setState deviation | PASS | Documented in class comment |
| File length | PASS | 194 lines (limit: 200) |

### Issues found

| # | Severity | Issue |
|---|----------|-------|
| 1 | MEDIUM | Error heading uses `titleMedium` instead of `headlineMedium` per tokens.md |
| 2 | LOW | Loading overlay uses `DeelmarktColors.white.withValues(alpha: 0.8)` — in dark mode should use scaffold dark color |
| 3 | LOW | Error state `neutral500` has no dark mode variant |
