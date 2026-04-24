# Shipping QR Screen (Reference — Implemented)

> Task: B-29 | Epic: E05 | Status: **Implemented** | File: `lib/features/shipping/presentation/screens/shipping_qr_screen.dart`

---

## Screen Info

| Field | Value |
|-------|-------|
| Route | `/shipping/:id/qr` |
| Auth | Required |
| States | Data (QR displayed) — no loading/error (data passed as constructor param) |
| Responsive | ResponsiveBody wrapper (max 800px centered — see #206 / PR #207, bumped from 600 so the QR card + instruction + CTA stack doesn't read cramped on tablet/desktop) |
| Dark mode | Supported via theme |

## Current Layout (as implemented)

1. **AppBar** — "Pakket verzenden" (shipping.sendPackage)
2. **EscrowTrustBanner** — reusable trust banner widget
3. **ShippingQrCard** widget — carrier badge + QR code + tracking number + ship-by deadline
4. **Instruction card** — info surface background, info icon, "Scan bij een servicepunt" text
5. **Find service point button** — DeelButton primary, map pin icon, currently `onPressed: null` (not wired)

## Design Prompt (reference — match existing implementation)

> Prepend [DESIGN-SYSTEM-PREAMBLE.md](../DESIGN-SYSTEM-PREAMBLE.md) before this prompt.

```
SCREEN-SPECIFIC DESIGN: Shipping QR Screen (REFERENCE — already built)

This screen is implemented. Generate a design that MATCHES the existing code.

LAYOUT:
- AppBar: "Pakket verzenden" title
- EscrowTrustBanner: green left border (#16A34A), shield icon,
  "Beschermd door DeelMarkt Escrow" on trust-shield bg (#F0FDF4)
- ShippingQrCard: bordered card (1px neutral-200, radius xl 16px) containing:
  - Carrier badge: "PostNL" or "DHL" chip with carrier icon, radius full
  - Large QR code (200x200px) centered — generated from tracking barcode
  - Tracking number: tabular figures, monospaced, body-md semibold
  - Ship-by deadline: "Verzend voor 31 mrt 2026" in body-sm, neutral-500
- Instruction card: info-surface (#EFF6FF) background, radius lg (12px),
  info icon (#3B82F6), text "Scan deze code bij een PostNL/DHL servicepunt"
- "Zoek servicepunt" primary button with map-pin icon (full width)

CONTENT: PostNL label with tracking number "3SDEVC1234567", deadline 5 days out.

VARIATIONS: Light, Dark, DHL carrier variant (different badge color/icon),
Expanded desktop (centered max 800px via ResponsiveBody — QR card + instruction card + CTA stack needs more than 600px to breathe on tablet/desktop)
```

## Implementation Audit

### Design system compliance

| Check | Status | Notes |
|-------|--------|-------|
| Colors from `DeelmarktColors` | PASS | `infoSurface`, `info`, `neutral700`, `neutral50` |
| Typography from theme | PASS | `textTheme.bodyMedium`, `bodySmall` |
| Spacing from `Spacing` | PASS | `s4`, `s3`, `s6` |
| Radius from `DeelmarktRadius` | PASS | `lg` (12px) for instruction card |
| l10n keys (not hardcoded) | PASS | All text via `.tr()` |
| Semantics labels | PASS | Instruction card has `Semantics(label:)` |
| Responsive | PASS | `ResponsiveBody` wrapper |
| Dark mode | PASS | Via `Theme.of(context)` |
| Phosphor Icons | PASS | `PhosphorIcons.info`, `PhosphorIcons.mapPin` |
| File length | PASS | 90 lines (limit: 200) |

### Issues found

| # | Severity | Issue |
|---|----------|-------|
| 1 | LOW | "Find service point" button `onPressed: null` — disabled, not wired to ParcelShop selector. Comment says "Phase 2" but B-31 is implemented. Should be wired. |
| 2 | LOW | QR card uses hardcoded `size: 200` for QR code — could be responsive to screen width |
