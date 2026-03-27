# Home Screen (Seller Mode)

> Task: P-41 | Epic: E01 | Status: Not started | Priority: #9

---

## Design Prompt

> Prepend [DESIGN-SYSTEM-PREAMBLE.md](../DESIGN-SYSTEM-PREAMBLE.md) before this prompt.

```
SCREEN-SPECIFIC DESIGN: Home Screen (Seller Mode)

LAYOUT:
- App bar: "DeelMarkt" logo + buyer/seller mode toggle (pill switch, right side)
  Seller mode active (orange filled)
- Welcome: "Hallo, Mahmut" greeting
- Stats cards row (3 cards, horizontal scroll):
  "€ 1.247" Totale verkopen (Total sales) — green up arrow
  "8" Actieve advertenties (Active listings)
  "3" Ongelezen berichten (Unread messages) — orange badge
- "Actie vereist" (Action required) section:
  - "Verzend bestelling #1234" (Ship order) — orange left border, tap to open shipping QR
  - "Beantwoord bericht van Lisa" (Reply to message from Lisa) — tap to open chat
- "Mijn advertenties" (My listings) section:
  DeelCards in list view (not grid) showing: thumbnail, title, price,
  views count, favourites count, days active, status badge (Actief/Verkocht)
- "Nieuwe advertentie" (New listing) FAB button (bottom-right, orange circle + icon)

VARIATIONS (include all 4 states per preamble: loading skeleton, error, empty, data): Light, Dark, Expanded (stats row wider, listings in table format),
Empty state (new seller, no listings — "Start met verkopen" CTA)
```

---

## l10n keys
```
home.seller.hello: "Hallo, {name}" / "Hello, {name}"
home.seller.totalSales: "Totale verkopen" / "Total sales"
home.seller.activeListings: "Actieve advertenties" / "Active listings"
home.seller.unreadMessages: "Ongelezen berichten" / "Unread messages"
home.seller.actionRequired: "Actie vereist" / "Action required"
home.seller.shipOrder: "Verzend bestelling" / "Ship order"
home.seller.replyTo: "Beantwoord bericht van {name}" / "Reply to message from {name}"
home.seller.myListings: "Mijn advertenties" / "My listings"
home.seller.newListing: "Nieuwe advertentie" / "New listing"
home.seller.startSelling: "Start met verkopen" / "Start selling"
home.seller.views: "{count} weergaven" / "{count} views"
home.seller.daysActive: "{count} dagen actief" / "{count} days active"
```
