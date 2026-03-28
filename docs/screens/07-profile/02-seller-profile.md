# Seller Profile (Public) Screen

> Task: P-39 | Epic: E06 | Status: Not started | Priority: #14

---

## Design Prompt

> Prepend [DESIGN-SYSTEM-PREAMBLE.md](../DESIGN-SYSTEM-PREAMBLE.md) before this prompt.

```
SCREEN-SPECIFIC DESIGN: Public Seller Profile Screen

LAYOUT:
- Avatar (80px) + name "Jan de Vries" + "Lid sinds jan 2025"
- Verification badges: email ✓, phone ✓, iDIN ✓ (all green shields)
- Rating: large "4.8" with 5 star icons + "(12 beoordelingen)"
- Stats: "23 verkocht" | "< 1 uur responstijd"
- "Bericht sturen" (Message) secondary button
- Tabs: "Advertenties" (12) | "Beoordelingen" (12)
  - Listings: 2-col DeelCard grid of seller's active items
  - Reviews: chronological list with stars, text, reviewer name, date
    Rating hidden if < 3 reviews ("Te weinig beoordelingen om gemiddelde te tonen")

STATES: Loading (skeleton shimmer), Error ("Dat lukte niet — probeer opnieuw"),
Empty (see specific empty state below), Data (normal content)

VARIATIONS: Light, Dark, Expanded, Few reviews state (< 3, avg hidden),
No listings state
```
