# Listing Detail Screen

> Task: P-25 | Epic: E01 | Status: Placeholder | Priority: #2

---

## Screen Info

| Field | Value |
|-------|-------|
| Route | `/listings/:id` |
| Auth | Required |
| States | Loading (skeleton), Data, Error, Sold, Own Listing |
| Responsive | Compact: full-width stacked, Expanded: 2-column (gallery left, details right) |
| Deep link | Yes — shareable URL |
| Dark mode | Required |

## Layout Sections (top to bottom)

1. **Image gallery** — Full-width hero, swipeable dots, pinch-to-zoom, max 12 images, Hero transition from DeelCard
2. **Trust banner** — "Beschermd door DeelMarkt Escrow" — green accent, shield icon, never dismissible
3. **Price + condition** — Bold price "€ 149,00", condition chip ("Als nieuw"), favourite heart
4. **Title + description** — Title (h2), description (body, expandable "Lees meer")
5. **Seller card** — Avatar + name + badges (verified email, phone, iDIN) + response time + rating stars + "Bekijk profiel" link
6. **Location** — Pin icon + city + distance + mini-map placeholder
7. **Similar listings** — Horizontal scroll of related DeelCards
8. **Action bar** (sticky bottom) — "Bericht sturen" (Message, secondary) + "Kopen" (Buy, primary orange)

## Variant: Own Listing
- No buy/message buttons
- Replace with: "Bewerken" (Edit) + "Verwijderen" (Delete, destructive)
- Show view count + favourite count

## Variant: Sold
- Grey overlay on images
- "VERKOCHT" badge
- No action buttons
- "Bekijk vergelijkbare" (View similar) CTA

---

## Design Prompt

> Prepend [DESIGN-SYSTEM-PREAMBLE.md](../DESIGN-SYSTEM-PREAMBLE.md) before this prompt.

```
Design a mobile product listing detail screen for "DeelMarkt", a Dutch P2P
marketplace. The screen should build trust and make the buyer feel safe.

LAYOUT (top to bottom):
1. Full-width image gallery with swipe dots indicator. Show a second-hand
   bicycle (fiets) as the product. Image fills width, 4:3 aspect ratio.
   Back arrow top-left, share icon top-right, favourite heart top-right (44x44).

2. Trust banner below image: trust-verified green (#16A34A) left border,
   shield-check icon, text "Beschermd door DeelMarkt Escrow" on
   trust-shield bg (#F0FDF4). Always visible, never dismissible.

3. Price section: "€ 149,00" in price token (20px Bold), next to condition
   chip "Als nieuw" in rounded pill (radius full 999px, xs badge).

4. Title: "Canyon Speedmax CF SLX" in heading-md (20px SemiBold).
   Description: 2-3 lines of Dutch text about the bike, with "Lees meer..."
   expandable link.

5. Seller card: rounded card with:
   - Avatar (48px circle) with a small green verification dot
   - Name "Jan de Vries"
   - Trust badges row: email ✓, phone ✓, iDIN ✓ (small shield icons)
   - "Reageert binnen 2 uur" (Responds within 2 hours)
   - 4.8 ★★★★☆ (12 beoordelingen)
   - "Bekijk profiel →" link

6. Location: pin icon + "Amsterdam, 1.2 km" with a subtle map preview
   (grey placeholder rectangle with pin marker)

7. "Vergelijkbare advertenties" (Similar listings) — horizontal scroll of
   3-4 smaller DeelCards

8. Sticky bottom action bar (elevation 1, white/surface background):
   - Left: "Bericht sturen" (Message seller) — secondary button (#1E4F7A)
   - Right: "Kopen — € 149,00" — primary button (#F15A24, white text)
   - Both buttons: Large size (52px height), radius lg (12px)

STYLE NOTES (in addition to preamble):
- Product photos: bright, natural, real second-hand items
- The screen should feel safe and premium — trust elements prominent

VARIATIONS NEEDED:
1. Light mode
2. Dark mode (#121212 scaffold, #1E1E1E cards)
3. Sold state (grey overlay, "VERKOCHT" badge, no action buttons)
4. Own listing state (Edit + Delete buttons instead of Buy + Message)
5. Tablet: 2-column layout (gallery left 60%, details right 40%)
6. Loading state (skeleton shimmer)

OUTPUT: High-fidelity UI mockup, iPhone 15 Pro frame, 1290x2796px.
```

---

## Implementation Notes

### Flutter widgets needed
- `ListingDetailScreen` — main screen with `CustomScrollView`
- `ImageGallery` (P-30) — swipe, dots, pinch-zoom, Hero
- `TrustBanner` (P-21) — already exists as `EscrowTrustBanner`
- `PriceTag` (P-31) — Euro formatting
- `SellerCard` — avatar + badges + rating + response time
- `LocationBadge` (P-32) — pin + distance
- `DeelCard` — for similar listings row
- Uses `AsyncNotifier`: `ListingDetailViewModel`
- Data from: `ListingRepository.getById()`, `UserRepository.getProfile(sellerId)`

### Responsive behavior
- **Compact:** Stacked single column, sticky bottom bar
- **Expanded:** 2-column (gallery 60% left, scrollable details 40% right), action bar in details column

### Accessibility
- Image gallery: `Semantics(image: true, label: 'Productfoto 1 van 5')`
- Trust banner: `Semantics(label: 'Escrow bescherming actief')`
- Buy button: `Semantics(button: true, label: 'Kopen voor 149 euro')`
- Seller card: `Semantics(label: 'Verkoper Jan de Vries, 4.8 sterren, geverifieerd')`

### l10n keys needed
```
listing.protectedByEscrow: "Beschermd door DeelMarkt Escrow" / "Protected by DeelMarkt Escrow"
listing.likeNew: "Als nieuw" / "Like new"
listing.readMore: "Lees meer..." / "Read more..."
listing.respondsWithin: "Reageert binnen {time}" / "Responds within {time}"
listing.viewProfile: "Bekijk profiel" / "View profile"
listing.similar: "Vergelijkbare advertenties" / "Similar listings"
listing.sold: "VERKOCHT" / "SOLD"
listing.viewSimilar: "Bekijk vergelijkbare" / "View similar"
listing.buy: "Kopen" / "Buy"
listing.message: "Bericht sturen" / "Message seller"
listing.edit: "Bewerken" / "Edit"
listing.delete: "Verwijderen" / "Delete"
```
