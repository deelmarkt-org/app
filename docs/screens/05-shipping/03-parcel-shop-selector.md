# ParcelShop Selector Screen (Reference — Implemented)

> Task: B-31 | Epic: E05 | Status: **Implemented** | File: `lib/features/shipping/presentation/screens/parcel_shop_selector_screen.dart`

---

## Screen Info

| Field | Value |
|-------|-------|
| Route | `/shipping/:id/parcel-shops` |
| Auth | Required |
| States | Data (shop list), Empty (no shops found), Selected (detail panel) |
| Responsive | Compact: full-width list + bottom select bar. Expanded: master-detail (380px list + detail panel) |
| Dark mode | Supported — explicit `isDark` checks on borders and colors |

## Current Layout (as implemented)

### Compact (<600px)
1. **AppBar** — "Servicepunt kiezen" (shipping.selectParcelShop)
2. **Shop list** — `ListView.separated` of `ParcelShopListItem` widgets:
   - Carrier icon (44x44) + shop name (bold) + address + distance
   - Selected: primary border highlight
3. **Bottom select bar** (shown when item selected) — "Kies dit servicepunt" primary button

### Expanded (>=600px)
1. **AppBar** — same
2. **Master-detail layout** — 380px shop list (left) | vertical divider | detail panel (right)
3. **Detail panel** — `ParcelShopDetailPanel`: name, address, distance, opening hours, select button
4. **Empty detail** — storefront icon + "Selecteer een servicepunt uit de lijst"

## Design Prompt (reference — match existing implementation)

> Prepend [DESIGN-SYSTEM-PREAMBLE.md](../DESIGN-SYSTEM-PREAMBLE.md) before this prompt.

```
SCREEN-SPECIFIC DESIGN: ParcelShop Selector Screen (REFERENCE — already built)

LAYOUT — show BOTH compact and expanded side by side:

COMPACT (mobile):
- AppBar: "Servicepunt kiezen"
- List of 4-5 service points, each row:
  - Carrier icon (PostNL orange / DHL yellow, 44x44, radius full)
  - Shop name bold (body-lg): "PostNL Punt - Albert Heijn Kalverstraat"
  - Address (body-sm, neutral-500): "Kalverstraat 1, Amsterdam"
  - Distance (body-sm, neutral-500): "350m"
  - Selected row: primary (#F15A24) left border accent
- Bottom select bar (sticky, elevation 1): "Kies dit servicepunt" primary button

EXPANDED (desktop/tablet):
- Master-detail layout: 380px list left | 1px divider | detail panel right
- Detail panel for selected shop:
  - Large shop name (heading-md)
  - Full address with map-pin icon
  - Distance badge
  - Opening hours rows (day + time pairs)
  - "Selecteren" primary button
- Empty detail state: storefront icon (48px, neutral-300) +
  "Selecteer een servicepunt uit de lijst"

CONTENT: Mix of PostNL and DHL service points in Amsterdam.
Names like "Albert Heijn", "Bruna", "DHL ServicePoint".

VARIATIONS: Light, Dark, Empty state (no shops found —
map-pin-area icon + "Geen servicepunten gevonden"),
Compact with selected item (bottom bar visible)
```

## Implementation Audit

### Design system compliance

| Check | Status | Notes |
|-------|--------|-------|
| Colors from `DeelmarktColors` | PASS | `neutral200`, `neutral300`, `neutral500`, `darkBorder`, `darkOnSurfaceSecondary` |
| Typography from theme | PASS | `bodyMedium`, `bodySmall`, etc. |
| Spacing from `Spacing` | PASS | `s3`, `s4` |
| Radius | PASS | Uses design system tokens |
| l10n keys | PASS | All text via `.tr()` |
| Semantics labels | PASS | `ParcelShopListItem` has `Semantics(button: true, selected:, label:)` |
| Responsive | PASS | `Breakpoints.isCompact()` splits compact/expanded layout |
| Dark mode | PASS | Explicit `isDark` checks for border and text colors |
| Phosphor Icons | PASS | `PhosphorIcons.storefront`, `mapPinArea`, `checkCircle` |
| File length | PASS | 175 lines (limit: 200) |
| Named constant for magic number | PASS | `_masterPanelWidth = 380` |
| setState deviation documented | PASS | Comment explains ephemeral UI state deviation from §1.3 |

### Issues found

| # | Severity | Issue |
|---|----------|-------|
| 1 | LOW | `separatorBuilder: (_, _)` uses dual wildcard — requires Dart 3.7+. Same issue flagged in PR #14 for `app_router.dart`. |
| 2 | LOW | Empty detail placeholder uses `neutral300` for icon without dark mode variant — should use `isDark ? darkOnSurfaceSecondary : neutral300`. The list and select bar correctly use `isDark` checks. |
