# Listing Creation Screen

> Task: P-24 | Epic: E01 | Status: Not started | Priority: #7

---

## Screen Info

| Field | Value |
|-------|-------|
| Route | `/sell` (from bottom nav) → multi-step flow |
| Auth | Required |
| States | Photo capture, Form, Quality score, Publishing, Published success |
| Responsive | Compact: full-screen steps, Expanded: 2-column (preview left, form right) |
| Dark mode | Required |

## Flow Steps

### Step 1 — Photos (photo-first approach)
- Camera opens immediately (or gallery picker)
- Grid of selected photos (drag to reorder, X to remove)
- "Foto's toevoegen" (Add photos) button
- Max 12 photos, minimum 1
- Progress: "3 van 12 foto's" (3 of 12 photos)

### Step 2 — Details form
- Titel (Title) — text input, required
- Beschrijving (Description) — multiline, expandable
- Categorie (Category) — dropdown: L1 → L2 subcategory
- Conditie (Condition) — segmented: Nieuw, Als nieuw, Goed, Redelijk
- Prijs (Price) — EUR input with € prefix, numeric keyboard
- Verzending (Shipping) — PostNL / DHL toggle, weight range selector
- Locatie (Location) — auto-detected or manual postcode entry

### Step 3 — Quality score + publish
- Quality score bar: 0-100, red (<40) / amber (40-70) / green (>70)
- Per-field breakdown: photos ✓, title ✓, description ✗ (te kort), price ✓
- Tips: "Voeg een langere beschrijving toe voor meer biedingen"
- "Publiceren" (Publish) button — primary orange
- "Opslaan als concept" (Save as draft) — ghost button

---

## Design Prompt

> Prepend [DESIGN-SYSTEM-PREAMBLE.md](../DESIGN-SYSTEM-PREAMBLE.md) before this prompt.

```
SCREEN-SPECIFIC DESIGN: Listing Creation Flow (3 steps)

Show 3 screens side by side:

STEP 1 — PHOTOS:
- "Nieuwe advertentie" header with close X
- Large photo grid (2x3) showing 3 uploaded bike photos + 3 empty slots
  with dashed borders and camera icon
- "Foto's toevoegen" button below grid
- "3 van 12 foto's" caption
- "Volgende" (Next) button at bottom

STEP 2 — DETAILS FORM:
- "Details" header with back arrow
- Title input: "Canyon Speedmax CF SLX"
- Description: multiline with 3 lines of Dutch text about the bike
- Category dropdown showing "Sport > Fietsen"
- Condition: segmented control with "Als nieuw" selected (orange)
- Price input: "€ 149,00" with EUR prefix
- Shipping: PostNL selected (radio), weight "0-2 kg"
- "Volgende" button

STEP 3 — QUALITY SCORE:
- "Kwaliteit" header
- Large circular progress indicator: 78/100 in green
- Bar breakdown:
  ✓ Foto's (5/5) — green
  ✓ Titel (4/5) — green
  ✗ Beschrijving (2/5) — amber, "Voeg meer details toe"
  ✓ Prijs (5/5) — green
  ✓ Categorie (5/5) — green
- Tip card: lightbulb icon + "Advertenties met 5+ foto's verkopen 3x sneller"
- "Publiceren" large orange button
- "Opslaan als concept" ghost button below

VARIATIONS: Light, Dark, Expanded (preview panel left showing live card
preview as user fills form), Success state (confetti + "Gepubliceerd!"
+ "Bekijk advertentie" button)
```

---

## l10n keys
```
sell.newListing: "Nieuwe advertentie" / "New listing"
sell.addPhotos: "Foto's toevoegen" / "Add photos"
sell.photosCount: "{count} van {max} foto's" / "{count} of {max} photos"
sell.details: "Details" / "Details"
sell.title: "Titel" / "Title"
sell.description: "Beschrijving" / "Description"
sell.category: "Categorie" / "Category"
sell.condition: "Conditie" / "Condition"
sell.price: "Prijs" / "Price"
sell.shipping: "Verzending" / "Shipping"
sell.location: "Locatie" / "Location"
sell.quality: "Kwaliteit" / "Quality"
sell.publish: "Publiceren" / "Publish"
sell.saveDraft: "Opslaan als concept" / "Save as draft"
sell.published: "Gepubliceerd!" / "Published!"
sell.viewListing: "Bekijk advertentie" / "View listing"
sell.next: "Volgende" / "Next"
sell.tipMorePhotos: "Advertenties met 5+ foto's verkopen 3x sneller" / "Listings with 5+ photos sell 3x faster"
```
