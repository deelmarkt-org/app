# Listing Cards — Governance (ADR-024)

`DeelCard` (`.grid` and `.list` variants) is the **single canonical listing card** for DeelMarkt.

## Rule

Do **not** create new `*_card.dart` files under `lib/features/**/presentation/widgets/` that implement a grid-style listing card. All card features (new badges, overlay states, condition chips, sold overlays) belong in `lib/widgets/cards/deel_card.dart`.

Feature-level wiring (which listings to show, navigation callbacks, provider reads) stays in the feature's `presentation/` layer — only the visual card component is shared.

## Why

Prior to ADR-024 (2026-04-17), `ListingCard` in `lib/features/home/` duplicated `DeelCard.grid`, causing every new card feature to require two implementations. The duplication was eliminated by consolidating on `DeelCard.grid`. See [ADR-024](../../docs/adr/ADR-024-listing-card-consolidation.md) for full rationale.

## API surface

| Widget | Variants | Use when |
|:-------|:---------|:---------|
| `DeelCard.grid` | — | Grid layout (home, search, favourites, profile) |
| `DeelCard.list` | — | Horizontal list / search list mode |
| `SkeletonListingCard` | — | Loading placeholder for grid |

All are exported from `package:deelmarkt/widgets/cards/deel_card.dart`.
