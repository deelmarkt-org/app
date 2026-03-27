# Own Profile Screen

> Task: P-17 | Epic: E02 | Status: Placeholder | Priority: #5

---

## Design Prompt

> Prepend [DESIGN-SYSTEM-PREAMBLE.md](../DESIGN-SYSTEM-PREAMBLE.md) before this prompt.

```
SCREEN-SPECIFIC DESIGN: Own Profile Screen

LAYOUT:
- Large avatar (80px) centered with camera edit overlay icon
- Name "Mahmut Kaya" in h1, joined date "Lid sinds maart 2026"
- Verification badges row: email ✓ (green), phone ✓ (green), iDIN ✗ (grey)
  "Verifieer je identiteit" (Verify identity) CTA link for incomplete badges
- Stats row: "12 verkocht" | "4.8 ★ (8 beoordelingen)" | "< 2 uur responstijd"
- Tabs: "Advertenties" (Listings) | "Beoordelingen" (Reviews)
  - Listings tab: grid of own DeelCards with status badges (Actief/Verkocht/Concept)
  - Reviews tab: list of review cards (star, text, reviewer name, date)
- Settings gear icon in top-right → navigates to Settings screen

CONTENT: Dutch user, mix of active and sold listings. Reviews from other Dutch users.

VARIATIONS (include all 4 states per preamble: loading skeleton, error, empty, data): Light, Dark, Expanded (wider layout, 3-col listing grid),
Empty state (new user, no listings yet — "Plaats je eerste advertentie" CTA),
Other user's profile view (no edit buttons, "Bericht sturen" CTA instead)
```

---

## l10n keys
```
profile.memberSince: "Lid sinds {date}" / "Member since {date}"
profile.verifyIdentity: "Verifieer je identiteit" / "Verify your identity"
profile.sold: "{count} verkocht" / "{count} sold"
profile.reviews: "{count} beoordelingen" / "{count} reviews"
profile.responseTime: "< {time} responstijd" / "< {time} response time"
profile.listings: "Advertenties" / "Listings"
profile.reviewsTab: "Beoordelingen" / "Reviews"
profile.active: "Actief" / "Active"
profile.sold: "Verkocht" / "Sold"
profile.draft: "Concept" / "Draft"
profile.firstListing: "Plaats je eerste advertentie" / "Post your first listing"
```
