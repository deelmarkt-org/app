# Admin Moderation Panel

> Task: P-40 | Epic: E06 | Status: Not started | Priority: #18

---

## Design Prompt

> Prepend [DESIGN-SYSTEM-PREAMBLE.md](../DESIGN-SYSTEM-PREAMBLE.md) before this prompt.

```
SCREEN-SPECIFIC DESIGN: Admin Moderation Panel (Web/Desktop only)

LAYOUT — Dashboard with sidebar navigation:
- Sidebar (240px): DeelMarkt logo, nav items:
  Dashboard, Gemelde advertenties (Flagged listings), Gemelde gebruikers
  (Reported users), Geschillen (Disputes), DSA Meldingen (DSA Notices), Beroepen (Appeals)
- Main content area with table views:

DASHBOARD tab:
- 4 stat cards: "12 Open geschillen" | "3 DSA meldingen (< 24u)" |
  "156 Actieve advertenties" | "€ 12.450 in escrow"
- SLA timer bar: "DSA 24-uur SLA: 2 van 3 binnen tijd afgehandeld"
- Recent activity feed

FLAGGED LISTINGS tab:
- Table: Thumbnail | Titel | Verkoper | Reden | Datum | Ernst | Actie
- Actions: Goedkeuren / Verwijderen / Waarschuwen
- Filter chips: Ernst (Hoog/Midden/Laag), Status, Categorie

DISPUTES tab:
- Table: Order # | Koper | Verkoper | Bedrag | Status | SLA countdown
- Dispute detail: timeline of events, messages, evidence, resolution buttons

NOTE: Desktop-only layout. No mobile responsive needed. Use NavigationRail
or persistent sidebar. This is an internal tool — functional over beautiful.

VARIATIONS (include all 4 states per preamble: loading skeleton, error, empty, data): Light only (admin tools don't need dark mode),
Empty dashboard (new platform, no data)
```
