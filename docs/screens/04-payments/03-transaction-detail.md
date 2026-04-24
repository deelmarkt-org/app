# Transaction Detail Screen (Reference — Implemented)

> Task: B-24 | Epic: E03 | Status: **Implemented** | File: `lib/features/transaction/presentation/screens/transaction_detail_screen.dart`

---

## Screen Info

| Field | Value |
|-------|-------|
| Route | `/transactions/:id` |
| Auth | Required |
| States | Data (timeline varies by transaction status) — no loading/error (data passed as param) |
| Responsive | ResponsiveBody wrapper (max 900px centered). Expanded ≥840px renders a two-column `Row` — main content (TrustBanner + AmountSection + ActionSection) on the left, EscrowTimeline pinned as a 320px right rail so it stays in view while scrolling. Compact stacks everything in a single column with the timeline at the top. See #206. |
| Dark mode | Via Theme, but sub-widgets may have light-only colors |

## Current Layout (as implemented)

1. **AppBar** — "Transactiestatus" (transaction.status)
2. **EscrowTrustBanner** — reusable trust banner (green border, shield icon)
3. **EscrowTimeline** — horizontal stepper showing payment flow:
   - Steps: Betaald → Verzonden → Afgeleverd → Bevestigd → Vrijgegeven
   - Active step highlighted, completed steps with checkmarks
   - Escrow deadline shown if applicable
4. **AmountSection** — price breakdown card:
   - Artikelprijs (item), Platformkosten (fee), Verzendkosten (shipping)
   - Divider
   - **Totaal** (bold, larger)
5. **ActionSection** — context-dependent buttons:
   - `delivered` status: "Levering bevestigen" (success) + "Geschil openen" (destructive)
   - Other statuses: different button combinations

## Design Prompt (reference)

> Prepend [DESIGN-SYSTEM-PREAMBLE.md](../DESIGN-SYSTEM-PREAMBLE.md) before this prompt.

```
SCREEN-SPECIFIC DESIGN: Transaction Detail Screen (REFERENCE — already built)

LAYOUT:
- AppBar: "Transactiestatus" title
- EscrowTrustBanner: green (#16A34A) left border, shield icon,
  "Beschermd door DeelMarkt Escrow" on trust-shield bg (#F0FDF4)
- EscrowTimeline: horizontal 5-step stepper:
  Steps: "Betaald" → "Verzonden" → "Afgeleverd" → "Bevestigd" → "Vrijgegeven"
  Active step: primary orange (#F15A24) circle with current icon, pulsing
  Completed: trust-escrow blue (#2563EB) circle with checkmark
  Pending: grey dashed circle (neutral-300 light, neutral-500 dark)
  Connected by horizontal lines (solid for completed, dashed for pending)
  If escrow deadline set: "Bevestig voor 28 mrt 2026" subtitle under active step
- AmountSection: bordered card (1px neutral-200, radius xl 16px):
  Artikelprijs          € 149,00
  Platformkosten        €   1,50
  Verzendkosten         €   6,95
  ─────────────────────────────
  Totaal                € 157,45  (bold, price token)
  All prices: tabular figures, right-aligned
- ActionSection (for "delivered" status):
  "Levering bevestigen" — success button (#2EAD4A, white text, check-circle icon)
  "Geschil openen" — destructive button (#E53E3E, white text, warning-circle icon)

CONTENT: Show a transaction in "delivered" status (buyer's view) —
the most action-rich state with both confirm and dispute buttons visible.

VARIATIONS: Light, Dark, Different transaction states:
- "paid" (no actions, waiting for shipment)
- "shipped" (tracking link visible)
- "delivered" (confirm + dispute buttons)
- "confirmed" (waiting for payout)
- "released" (completed, payout done — green success state)
Expanded desktop (centered max 900px via ResponsiveBody, two-column `Row` — main content on left, 320px EscrowTimeline rail on right)
```

## Implementation Audit

| Check | Status | Notes |
|-------|--------|-------|
| Colors from `DeelmarktColors` | PASS | Via sub-widgets (EscrowTimeline, AmountSection, ActionSection) |
| Typography from theme | PASS | Via sub-widgets |
| Spacing from `Spacing` | PASS | `s4`, `s6` |
| l10n keys | PASS | `transaction.status` via `.tr()` |
| Semantics | PASS | Via sub-widgets (EscrowTrustBanner, AmountSection have Semantics) |
| Responsive | PASS | `ResponsiveBody(maxWidth: 900)` + two-column Row on expanded (see §Responsive above) |
| Dark mode | PARTIAL | Depends on sub-widget dark mode support |
| File length | PASS | 44 lines (very clean, delegates to sub-widgets) |

### Issues found

| # | Severity | Issue |
|---|----------|-------|
| 1 | RESOLVED | ~~No `ResponsiveBody` wrapper — screen stretches full-width on desktop.~~ Fixed by #195 (wrap) + #206 (maxWidth 900 + expanded two-column Row with timeline rail). |
| 2 | MEDIUM | ActionSection buttons have `onPressed: null` — not wired to ConfirmDeliveryUseCase or dispute flow |
| 3 | LOW | No loading/error states — data passed directly as constructor param. When ViewModels are added, will need `AsyncValue` handling. |
