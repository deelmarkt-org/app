# ADR-024: Listing Card Consolidation — `DeelCard.grid` as Canonical

### Status

**Accepted** — 2026-04-17 · Author: pizmam · **Supersedes:** implicit dual-card status quo

### Context

Two widgets render the same conceptual object ("listing card on a grid"):

| Widget | Path | Ownership | Features |
|:-------|:-----|:----------|:---------|
| `ListingCard` | `lib/features/home/presentation/widgets/listing_card.dart` | Feature (home) | `_ImageSection`, `_FavouriteButton`, inline `PriceTag`, `LocationBadge`. TODO(#59), TODO(#60). |
| `DeelCard.grid` / `DeelCard.list` | `lib/widgets/cards/deel_card.dart` | Shared widget lib | Hero, favourite toggle with bounce, `showEscrowBadge`, `DeelCardImage`, `DeelBadge`. Used by search, favourites, profile tabs. |

Status quo costs:
- Every new card feature (escrow badge, discount flag, condition chip) is implemented twice or drifts.
- Issue #59 already shipped `showEscrowBadge` on `DeelCard.grid` in a previous PR; `ListingCard` still has a TODO for the same feature.
- Issue #60 requires `CachedNetworkImage` wiring in both widgets — twice the test surface, twice the golden files.
- `CLAUDE.md §3.1` mandates "Before creating ANY new widget, check: Does it exist in `lib/widgets/`?" — `ListingCard` is a direct violation.

### Decision

**`DeelCard.grid` is canonical.** `ListingCard` is deprecated and migrated to `DeelCard.grid` across call sites within a single PR (`feature/pizmam-adr024-card-consolidation`), sequenced **before** issues #60 and #59 ship.

1. **Step 1 — API gap closure**: `DeelCard.grid` gains any `ListingCard` feature currently absent:
   - `onFavouriteTap` is already supported.
   - `distanceFormatted` is already supported.
   - A11y label format matches current `ListingCard` Semantics string.
2. **Step 2 — Call-site migration**: `grep -l "ListingCard" lib/` produces the call sites. Each is migrated in-file. Favourite-tap wiring preserved.
3. **Step 3 — Delete `ListingCard`** and its test file after all call sites migrated. Delete unused `_ImageSection`, `_FavouriteButton` private widgets.
4. **Step 4 — Governance guard**: add `lib/widgets/cards/README.md` with a one-paragraph note citing ADR-024, stating that `*_card.dart` files under `lib/features/**/presentation/widgets/` are disallowed for grid-style cards. A `custom_lint` rule may be added in a future tooling sprint; for now the README + code-review checklist is the enforcement mechanism.

### Consequences

#### Positive
- Single test surface for all card features; goldens maintained in one folder.
- Issues #60 and #59 become trivial — one touch point, not two.
- Memory/bundle: removing `_ImageSection` + `_FavouriteButton` (~200 LOC) is net-negative bundle size.
- Future card features (seller badge, discount stripe, sold overlay) have one home.
- Eliminates the architectural smell flagged in audit §C6.

#### Negative
- One migration PR of ~400 LOC (delete + call-site swap). Low risk because `DeelCard.grid` is production-tested in search/favourites/profile already.
- Golden files for `ListingCard` are deleted; `DeelCard.grid` goldens must cover the home-grid variant (already do).

### Alternatives Considered

1. **Keep both, add lint guard** — rejected: doesn't eliminate the existing duplication, only prevents new. Cost of living with duplication (double PRs per card feature) dominates.
2. **Promote `ListingCard` pattern** — rejected: `ListingCard` has fewer features (no Hero, no list variant, no escrow), and is not used outside home. Promoting means re-implementing `DeelCard`'s surface in the feature layer — wrong direction per Clean Architecture.
3. **Create a third abstraction `BaseListingCard`** — rejected: premature abstraction for 2 variants; `DeelCard.grid` + `DeelCard.list` already covers the known variants.

### Rollback

Single git revert of the consolidation PR restores `ListingCard`. Because `DeelCard.grid` predates this ADR and is untouched functionally, all other card consumers are unaffected.
