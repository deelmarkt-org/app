# Payment Summary Screen

> Task: (E03 implicit) | Epic: E03 | Status: Not started | Priority: #6

---

## Screen Info

| Field | Value |
|-------|-------|
| Route | `/transactions/:id/checkout` or modal |
| Auth | Required |
| States | Loading, Data (breakdown), Confirming (spinner), Error |
| Responsive | Compact: full-screen, Expanded: centered max 500px |
| Dark mode | Required |

## Layout

1. **Header** — "Bestelling bevestigen" (Confirm order)
2. **Listing summary card** — Image thumbnail + title + condition + seller name
3. **Shipping method** — PostNL / DHL radio selection + estimated delivery
4. **Address section** — Delivery address (from saved addresses or enter new)
5. **Price breakdown**:
   - Artikelprijs (Item price): € 149,00
   - Platformkosten (Platform fee): € 1,50
   - Verzendkosten (Shipping): € 6,95
   - **Totaal (Total): € 157,45** (bold, larger)
6. **Trust callout** — Shield icon + "Veilig betalen — je geld wordt pas vrijgegeven na ontvangst" (Safe payment — money released only after receipt)
7. **Pay button** — "Betalen met iDEAL — € 157,45" (primary orange, iDEAL logo)

---

## Design Prompt

> Prepend [DESIGN-SYSTEM-PREAMBLE.md](../DESIGN-SYSTEM-PREAMBLE.md) before this prompt.

```
SCREEN-SPECIFIC DESIGN: Payment Summary / Checkout Screen

LAYOUT:
- "Bestelling bevestigen" header with back arrow
- Listing summary card: small product thumbnail (64x64, rounded), title
  "Canyon Speedmax CF SLX", "Als nieuw", seller "Jan de Vries" with avatar
- Shipping method: two radio options
  ○ PostNL (logo) — "2-3 werkdagen" — € 6,95
  ● DHL (logo) — "1-2 werkdagen" — € 7,45 (selected)
- Delivery address card: "Kalverstraat 1, 1012AB Amsterdam"
  "Wijzigen" (Change) link in orange
- Price breakdown in a bordered card:
  Artikelprijs          € 149,00
  Platformkosten        €   1,50
  Verzendkosten (PostNL) €   6,95
  ─────────────────────────────
  Totaal                € 157,45  (bold, 20px)
- Trust callout: green background surface, shield icon,
  "Veilig betalen — je geld wordt pas vrijgegeven na ontvangst"
- Sticky bottom: "Betalen met iDEAL — € 157,45" large orange button
  with small iDEAL bank logo to the left of text

CONTENT: Use tabular/monospaced figures for prices. Price breakdown
should be right-aligned for the amounts. The total row should feel
visually distinct (bold, larger, divider above).

VARIATIONS: Light, Dark, Expanded (centered card), Loading state,
Error state (payment failed — red banner + retry button)
```

---

## l10n keys
```
checkout.confirmOrder: "Bestelling bevestigen" / "Confirm order"
checkout.shippingMethod: "Verzendmethode" / "Shipping method"
checkout.workDays: "{days} werkdagen" / "{days} business days"
checkout.deliveryAddress: "Afleveradres" / "Delivery address"
checkout.change: "Wijzigen" / "Change"
checkout.itemPrice: "Artikelprijs" / "Item price"
checkout.platformFee: "Platformkosten" / "Platform fee"
checkout.shippingCost: "Verzendkosten" / "Shipping cost"
checkout.total: "Totaal" / "Total"
checkout.safePayment: "Veilig betalen" / "Safe payment"
checkout.moneyHeldUntilReceipt: "Je geld wordt pas vrijgegeven na ontvangst" / "Money released only after receipt"
checkout.payWithIdeal: "Betalen met iDEAL" / "Pay with iDEAL"
```
