# Search Screen

> Task: P-26 | Epic: E01 | Status: Placeholder | Priority: #3

---

## Screen Info

| Field | Value |
|-------|-------|
| Route | `/search` |
| Auth | Required |
| States | Initial (recent searches), Typing (instant results), Results, Empty results, Error |
| Responsive | Compact: 2-col grid, Expanded: 3-5 col grid with filter sidebar |
| Bottom nav | Active: Search (magnifying glass) |
| Dark mode | Required |

## Layout Sections

### Initial state (no query)
1. **Search bar** — Large, centered, placeholder "Zoek op trefwoord..." (Search by keyword)
2. **Recent searches** — List of recent queries with clock icon, tappable, clear all
3. **Popular categories** — Grid of 4-6 popular category chips

### Results state
1. **Search bar** (top, sticky) — Query text, clear X button
2. **Filter chips** — Horizontal scroll: Prijs (Price), Conditie (Condition), Afstand (Distance), Categorie, Sorteer (Sort)
3. **Results count** — "24 resultaten voor 'fiets'" (24 results for 'fiets')
4. **Results grid** — DeelCards in 2-column grid (compact) or 3-5 column (expanded)
5. **Load more** — Infinite scroll with loading indicator at bottom

### Filter bottom sheet (when chip tapped)
- Price range slider (€0 – €5000)
- Condition checkboxes: Nieuw, Als nieuw, Goed, Redelijk
- Distance slider: 1km – 100km
- Category multi-select
- Sort: Relevantie, Prijs laag-hoog, Prijs hoog-laag, Nieuwste, Dichtbij

---

## Design Prompt

> Prepend [DESIGN-SYSTEM-PREAMBLE.md](../DESIGN-SYSTEM-PREAMBLE.md) before this prompt.

```
Design a mobile search screen for "DeelMarkt", a Dutch marketplace app.
Show TWO states: the initial empty search state and the results state.

STATE 1 — INITIAL (no query):
- Large search bar at top with magnifying glass icon and placeholder
  "Zoek op trefwoord..." in grey
- "Recente zoekopdrachten" (Recent searches) section with 3-4 items:
  clock icon + "mountainbike", "iphone 14", "bank", "kinderwagen"
  Each with an X to remove. "Alles wissen" (Clear all) link top-right.
- "Populaire categorieën" (Popular categories) section: 6 rounded
  chips with icons: Elektronica, Mode, Fietsen, Meubels, Telefoons, Sport

STATE 2 — RESULTS:
- Search bar at top (sticky) showing "fiets" with clear X
- Horizontal filter chips below: "Prijs ▾", "Conditie ▾", "Afstand ▾",
  "Categorie ▾", "Sorteer ▾" — each is a rounded outlined chip
- "24 resultaten" text in small grey
- 2-column grid of DeelCards showing various bicycles:
  product photo, "€ 149,00" bold price, "Canyon Speedmax",
  "Amsterdam, 1.2 km", favourite heart
- Subtle divider between cards, no heavy borders

STYLE NOTES (in addition to preamble):
- Active filter chips: filled primary-surface (#FFF3EE), primary text
- Inactive chips: outlined neutral-300, radius xxl (24px)
- Search input focus ring: 2px primary
- Results should feel fast and responsive — not cluttered

VARIATIONS:
1. Light mode
2. Dark mode
3. Empty results: friendly illustration + "Geen resultaten voor 'xyz'.
   Probeer andere zoektermen." (No results, try different keywords)
4. Filter bottom sheet open: price range slider + condition checkboxes
5. Tablet expanded: filter sidebar on left (240px), results grid on right
   (3-4 columns)

OUTPUT: High-fidelity UI mockup, iPhone 15 Pro frame, 1290x2796px.
Show both states side by side if possible.
```

---

## Implementation Notes

### Flutter widgets needed
- `SearchScreen` — `CustomScrollView` with `SliverAppBar` (search bar)
- `FilterChipBar` — horizontal `ListView` of filter chips
- `FilterBottomSheet` — modal with sliders, checkboxes, radio buttons
- `SearchResultsGrid` — `SliverGrid` with `DeelCard` widgets
- `RecentSearches` — simple `ListView` with `ListTile`
- Uses `AsyncNotifier`: `SearchViewModel`
- Data from: `ListingRepository.search(query, filters, offset, limit)`

### Responsive behavior
- **Compact:** Search bar top, filter chips horizontal scroll, 2-col grid
- **Expanded:** Search bar top, filter sidebar left (permanent), 3-5 col grid right

### l10n keys needed
```
search.placeholder: "Zoek op trefwoord..." / "Search by keyword..."
search.recentSearches: "Recente zoekopdrachten" / "Recent searches"
search.clearAll: "Alles wissen" / "Clear all"
search.popularCategories: "Populaire categorieën" / "Popular categories"
search.results: "{count} resultaten" / "{count} results"
search.resultsFor: "{count} resultaten voor '{query}'" / "{count} results for '{query}'"
search.noResults: "Geen resultaten" / "No results"
search.tryDifferent: "Probeer andere zoektermen" / "Try different keywords"
search.filter.price: "Prijs" / "Price"
search.filter.condition: "Conditie" / "Condition"
search.filter.distance: "Afstand" / "Distance"
search.filter.category: "Categorie" / "Category"
search.filter.sort: "Sorteer" / "Sort"
search.sort.relevance: "Relevantie" / "Relevance"
search.sort.priceLowHigh: "Prijs laag-hoog" / "Price low-high"
search.sort.priceHighLow: "Prijs hoog-laag" / "Price high-low"
search.sort.newest: "Nieuwste" / "Newest"
search.sort.nearest: "Dichtbij" / "Nearest"
```
