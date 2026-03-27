# Home Screen (Buyer Mode)

> Task: P-29 | Epic: E01 | Status: Placeholder | Priority: #1

---

## Screen Info

| Field | Value |
|-------|-------|
| Route | `/` (root) |
| Auth | Required (redirect to onboarding if not logged in) |
| States | Loading (skeleton), Data, Empty (new user, no nearby), Error |
| Responsive | Compact: single column, Expanded: multi-column grid |
| Bottom nav | Active: Home (filled house icon) |
| Dark mode | Required |

## Layout Sections (top to bottom)

1. **App bar** — DeelMarkt logo (left), search icon (right), notification bell (right)
2. **Category carousel** — Horizontal scroll of 8 L1 categories with icons + labels
3. **Trust banner** — "Veilig kopen met escrow bescherming" (safe buying with escrow protection) — green left border, shield icon
4. **Nearby listings** — Section header "In de buurt" (Nearby) with "Bekijk alles" (View all) link — 2-column grid of DeelCards
5. **Recent listings** — Section header "Recent toegevoegd" (Recently added) — horizontal scroll of DeelCards
6. **Promoted section** (Phase 2) — Placeholder for promoted listings

## Component Specs

### DeelCard (listing card — from components.md)
- Image thumbnail (4:3 ratio, radius xl 16px)
- Favourite heart: 44x44 tap target, top-right overlay
- Trust badge: small shield, bottom-left of image
- Below image: price-sm (16px Bold) FIRST → "€ 45,00"
- Title: body-md (14px), max 2 lines, ellipsis
- Location: body-sm (12px), neutral-500 — pin icon + "Amsterdam · 2,3 km"
- "Escrow beschikbaar": body-sm, trust-verified green
- Card: 1px neutral-200 border, radius xl (16px), NO shadow

### Category pill
- Circular icon (48x48) with subtle background tint
- Label below: 1 line, caption size
- Categories: Elektronica, Mode, Huis & Tuin, Sport, Auto & Fiets, Boeken, Kinderen, Overig

---

## Design Prompt

> Prepend the content from [DESIGN-SYSTEM-PREAMBLE.md](../DESIGN-SYSTEM-PREAMBLE.md) before this prompt.

```
SCREEN-SPECIFIC DESIGN: Home Screen (Buyer Mode)

LAYOUT (top to bottom):
1. App bar: "DeelMarkt" logo text (orange) left, search icon + notification
   bell right. White/surface background.

2. Category carousel: 8 horizontal scrollable circular icons (48x48) with
   subtle orange-tinted backgrounds and caption labels below:
   Elektronica, Mode, Huis & Tuin, Sport, Auto & Fiets, Boeken, Kinderen, Overig

3. Trust banner: card with green left border, shield-check icon, text
   "Veilig kopen met escrow bescherming". Subtle green surface background.

4. "In de buurt" (Nearby) section header with "Bekijk alles →" link.
   2-column grid of DeelCards: product photo (4:3 ratio, radius xl 16px), bold price "€ 25,00",
   title, location "1.2 km", heart favourite overlay, seller avatar mini.

5. "Recent toegevoegd" (Recently added) — horizontal scroll of smaller DeelCards.

6. Bottom nav: Home (active/filled), Search, Sell (+), Messages, Profile.

CONTENT: Show realistic Dutch products — fiets, sneakers, IKEA bank, laptop.

VARIATIONS NEEDED:
1. Light mode (compact/mobile)
2. Dark mode (compact/mobile)
3. Expanded/desktop (3-4 col grid, NavigationRail instead of bottom bar)
4. Loading state (skeleton shimmer)
5. Empty state (no nearby — illustration + "Start met zoeken" CTA)

OUTPUT: iPhone 15 Pro frame (1290x2796px) for mobile, browser frame for desktop.
```

---

## Implementation Notes

### Flutter widgets needed
- `HomeScreen` — main scaffold with `RefreshIndicator`
- `CategoryCarousel` — horizontal `ListView` of `CategoryPill` widgets
- `ListingGrid` — `SliverGrid` with `DeelCard` widgets
- `ListingRow` — horizontal `ListView` with `DeelCard` (compact variant)
- Uses `AsyncNotifier` ViewModel: `HomeViewModel`
- Data from: `ListingRepository.getRecent()`, `ListingRepository.getNearby()`, `CategoryRepository.getAll()`

### Responsive behavior
- **Compact (<600px):** Single column, bottom nav, 2-col listing grid
- **Medium (600-840px):** Still bottom nav, 3-col listing grid
- **Expanded (>=840px):** Side `NavigationRail`, 4-5 col listing grid, wider cards

### Accessibility
- Category pills: `Semantics(button: true, label: 'Categorie: Elektronica')`
- DeelCard: `Semantics(label: 'Listing: iPhone 14, €450, 1.2 km')`
- Favourite heart: `Semantics(button: true, label: 'Toevoegen aan favorieten')`
- Trust banner: `Semantics(label: 'Escrow bescherming actief')`
- Loading: `Semantics(label: 'Laden...')`

### l10n keys needed
```
home.nearby: "In de buurt" / "Nearby"
home.viewAll: "Bekijk alles" / "View all"
home.recentlyAdded: "Recent toegevoegd" / "Recently added"
home.emptyNearby: "Geen advertenties in de buurt" / "No listings nearby"
home.startSearching: "Start met zoeken" / "Start searching"
nav.home: "Home" / "Home"
nav.search: "Zoeken" / "Search"
nav.sell: "Verkopen" / "Sell"
nav.messages: "Berichten" / "Messages"
nav.profile: "Profiel" / "Profile"
```
