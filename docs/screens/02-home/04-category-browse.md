# Category Browse Screen

> Task: P-27 | Epic: E01 | Status: Not started | Priority: #16

---

## Design Prompt

> Prepend [DESIGN-SYSTEM-PREAMBLE.md](../DESIGN-SYSTEM-PREAMBLE.md) before this prompt.

```
SCREEN-SPECIFIC DESIGN: Category Browse Screen

LAYOUT:
- "Categorieën" header with back arrow
- L1 categories: large cards (full-width, 80px height) with icon left,
  name center, arrow right, subtle background tint per category:
  Elektronica (blue tint), Mode (pink), Huis & Tuin (green),
  Sport (orange), Auto & Fiets (teal), Boeken (amber), Kinderen (purple), Overig (grey)
- When L1 is tapped → slide to L2 subcategories:
  "Sport" header with back, grid of subcategory chips:
  Fietsen, Fitness, Voetbal, Tennis, Hardlopen, Watersport, Wintersport, Overig

VARIATIONS: Light, Dark, Expanded (2-column L1 grid, L2 as sidebar),
Loading (skeleton cards)
```
