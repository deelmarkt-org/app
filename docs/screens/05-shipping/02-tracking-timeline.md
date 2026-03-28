# Tracking Timeline Screen (Reference — Implemented)

> Task: B-30 | Epic: E05 | Status: **Implemented** | File: `lib/features/shipping/presentation/screens/tracking_screen.dart`

---

## Screen Info

| Field | Value |
|-------|-------|
| Route | `/shipping/:id/tracking` |
| Auth | Required |
| States | Data (events list), Empty (no updates yet) |
| Responsive | ResponsiveBody wrapper (max 600px centered) |
| Dark mode | Supported via theme |

## Current Layout (as implemented)

1. **AppBar** — "Tracking" (tracking.title)
2. **Carrier header** — package icon + "PostNL Zending" / "DHL Zending" (heading-md semibold)
3. **Tracking number card** — neutral-50 bg, 1px neutral-200 border, radius lg:
   - Barcode icon + label "Trackingnummer" (body-sm, neutral-500)
   - Number: tabular figures, semibold, letter-spacing 1.2
4. **Updates section** — "Tracking updates" heading (titleSmall)
5. **TrackingTimeline widget** — vertical stepper with status icons, locations, timestamps
6. **Empty state** — clock icon (48px, neutral-300) + "Nog geen updates" text

## Design Prompt (reference — match existing implementation)

> Prepend [DESIGN-SYSTEM-PREAMBLE.md](../DESIGN-SYSTEM-PREAMBLE.md) before this prompt.

```
SCREEN-SPECIFIC DESIGN: Tracking Timeline Screen (REFERENCE — already built)

LAYOUT:
- AppBar: "Tracking" title
- Carrier header row: package icon (secondary blue #1E4F7A) + "PostNL Zending"
  in heading-md (20px SemiBold)
- Tracking number card: neutral-50 (#F8F9FB) bg, 1px neutral-200 border,
  radius lg (12px):
  - Barcode icon (neutral-700) + "Trackingnummer" label (body-sm, neutral-500)
  - "3SDEVC1234567" in body-md semibold, tabular figures, letter-spacing 1.2
- "Tracking updates" section header (heading-sm 18px SemiBold)
- Vertical timeline (TrackingTimeline widget):
  - Each event: status icon (color by status) + description + location + timestamp
  - Connected by vertical line between events
  - Most recent at top
  - Status icons: delivered (green check), in transit (blue truck),
    at service point (orange pin), label created (grey tag)
- Timestamps: localized short datetime ("25 mrt 2026 14:32")

CONTENT: 4 tracking events for a PostNL parcel: label created → dropped off →
in transit → delivered. Show Dutch locations (Amsterdam, Sorteerdepot Nieuwegein).

VARIATIONS: Light, Dark, Empty state (clock icon + "Nog geen updates"),
Expanded desktop (centered max 600px), DHL carrier variant
```

## Implementation Audit

### Design system compliance

| Check | Status | Notes |
|-------|--------|-------|
| Colors from `DeelmarktColors` | PASS | `secondary`, `neutral50`, `neutral200`, `neutral700`, `neutral500`, `neutral300` |
| Typography from theme | PASS | `titleMedium`, `bodySmall`, `bodyMedium`, `titleSmall` |
| Spacing from `Spacing` | PASS | `s1`, `s2`, `s3`, `s4`, `s6` |
| Radius from `DeelmarktRadius` | PASS | `lg` (12px) for tracking number card |
| l10n keys | PASS | All text via `.tr()` |
| Semantics labels | PASS | Carrier header, tracking number, empty state all have `Semantics` |
| Responsive | PASS | `ResponsiveBody` wrapper |
| Dark mode | PASS | Via `Theme.of(context)` — but see issue below |
| Phosphor Icons | PASS | `PhosphorIcons.package`, `PhosphorIcons.barcode`, `PhosphorIcons.clockCountdown` |
| Tabular figures | PASS | `FontFeature.tabularFigures()` on tracking number |
| File length | PASS | 162 lines (limit: 200) |

### Issues found

| # | Severity | Issue |
|---|----------|-------|
| 1 | MEDIUM | `titleMedium` and `titleSmall` used — these are Material TextTheme properties, not from DeelmarktTypography. Should use `headlineMedium` (20px SemiBold) and `headlineSmall` (18px SemiBold) per tokens.md. |
| 2 | LOW | No explicit dark mode `isDark` checks — relies entirely on `Theme.of(context)`. Works for text/backgrounds but custom neutral colors (`neutral50`, `neutral200`, `neutral300`, `neutral500`, `neutral700`) are light-mode only. |
