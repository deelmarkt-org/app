# Favourites Screen

> Task: P-28 | Epic: E01 | Status: Not started | Priority: #17

---

## Design Prompt

> Prepend [DESIGN-SYSTEM-PREAMBLE.md](../DESIGN-SYSTEM-PREAMBLE.md) before this prompt.

```
SCREEN-SPECIFIC DESIGN: Favourites Screen

LAYOUT:
- "Favorieten" (Favourites) header
- 2-column grid of DeelCards (same as home/search), but each card has
  a filled red heart icon (indicating it IS favourited)
- Long-press or swipe to unfavourite
- Pull-to-refresh

CONTENT: 6-8 saved Dutch listings with variety (electronics, fashion, bikes).

VARIATIONS (include all 4 states per preamble: loading skeleton, error, empty, data): Light, Dark, Expanded (3-4 col grid),
Empty state (empty heart illustration + "Nog geen favorieten.
Tik op het hartje bij een advertentie." CTA),
Unfavourited animation (card fades out with heart animation)
```

---

## l10n keys
```
favourites.title: "Favorieten" / "Favourites"
favourites.empty: "Nog geen favorieten" / "No favourites yet"
favourites.tapHeart: "Tik op het hartje bij een advertentie" / "Tap the heart on a listing"
favourites.removed: "Verwijderd uit favorieten" / "Removed from favourites"
favourites.undo: "Ongedaan maken" / "Undo"
```
