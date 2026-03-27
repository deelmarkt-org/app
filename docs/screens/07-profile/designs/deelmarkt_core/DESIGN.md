# Design System Strategy: The Honest Exchange

This design system is a comprehensive framework designed to elevate the P2P marketplace experience from a utility to a premium editorial destination. It balances the energy of Dutch commerce with a sophisticated, trust-first aesthetic that feels both authoritative and accessible.

---

## 1. Overview & Creative North Star

**Creative North Star: "The Curated Commons"**
The design system rejects the cluttered, "bargain-bin" aesthetic of traditional marketplaces. Instead, it treats every user listing like a boutique gallery piece. We break the "template" look through **intentional white space**, **overlapping depth**, and a **high-contrast typography scale** that guides the user’s eye through a narrative rather than a grid.

By utilizing asymmetric layouts—where imagery might slightly bleed over container edges—and bold, editorial type, we signal to the user that this is a space of quality, transparency, and premium service.

---

## 2. Colors & Surface Architecture

Our palette uses high-chroma brand accents anchored by a sophisticated range of neutral "Paper" tones.

### The "No-Line" Rule
**Borders are a failure of hierarchy.** Within this system, 1px solid lines are prohibited for sectioning. Boundaries must be defined through background shifts or tonal transitions.
- *Example:* A `surface-container-low` section sitting on a `surface` background provides enough contrast to define a zone without the "cheapening" effect of a stroke.

### Surface Hierarchy & Nesting
Think of the UI as physical layers of fine Dutch paper and frosted glass.
- **Base Layer:** `surface` (#fcf9f8).
- **Secondary Zones:** `surface-container-low` (#f6f3f2).
- **Interactive Cards:** `surface-container-lowest` (#ffffff) to provide a "lifted" feel against the background.
- **Deep Nesting:** Use `surface-container-high` (#ebe7e7) for inset elements like search bars or filter trays to create perceived "recessed" depth.

### Glass & Gradient
To move beyond a flat digital feel, use **Glassmorphism** for floating elements (e.g., sticky headers or mobile navigation bars). Use `surface` at 80% opacity with a `24px` backdrop blur.
- **Signature CTA Texture:** Main buttons and hero highlights should use a subtle linear gradient from `primary` (#a93200) to `primary-container` (#d1430a) at a 135-degree angle. This adds a "soulful" dimension that flat hex codes lack.

---

## 3. Typography: Editorial Authority

We use **Plus Jakarta Sans** as our sole typeface, relying on extreme scale variance to create hierarchy.

- **Display (lg/md/sm):** Used for hero sections and major category headers. These should be tight-tracked (-0.02em) to feel impactful and modern.
- **Headline (lg/md/sm):** The "Voice" of the marketplace. Use these for product titles and section headers.
- **Title (lg/md/sm):** Reserved for secondary information and card headings.
- **Body & Label:** Prioritize legibility. Use `body-lg` for product descriptions to maintain a premium, easy-to-read "journal" feel.

*Hierarchy Note:* Always pair a `display-md` headline with a `body-lg` subtext. The jump in scale reinforces the "Premium" brand voice.

---

## 4. Elevation & Depth: Tonal Layering

Traditional drop shadows are often messy. We achieve depth through **Tonal Layering** and **Ambient Light**.

- **The Layering Principle:** Instead of a shadow, place a `surface-container-lowest` card on a `surface-container-low` background. The subtle 2% shift in brightness creates a sophisticated, "natural" lift.
- **Ambient Shadows:** For floating Modals or Popovers, use a shadow with a 40px blur, 0% spread, and an opacity of 6% using the `on-surface` color. This mimics natural light rather than a digital effect.
- **The Ghost Border:** If a boundary is strictly required for accessibility (e.g., in high-contrast situations), use the `outline-variant` token at **15% opacity**. Never use 100% opaque borders.

---

## 5. Components

### Buttons
- **Primary:** Gradient fill (`primary` to `primary-container`), `lg` (12px) radius, white text. No border.
- **Secondary:** `surface-container-high` background with `on-secondary-container` text. This feels "integrated" rather than "pasted."
- **Tertiary:** Pure text with `primary` color, used for low-emphasis actions like "Cancel" or "View More."

### Input Fields
- **Scaffold:** Use `surface-container-lowest` with a `lg` (12px) radius.
- **Focus State:** Instead of a heavy border, use a 2px `outline` of `primary` at 40% opacity and a subtle `surface-tint` inner glow.

### Cards & Lists
- **The Card Rule:** Forbid divider lines. Use `16px` (spacing-4) or `24px` (spacing-6) of vertical whitespace to separate items.
- **Visual Stacking:** On the homepage, marketplace cards should use the `xl` (16px) radius and a `surface-container-lowest` fill to pop against the `surface` background.

### Premium Marketplace Additions
- **Trust Badge:** A glassmorphic chip using `tertiary-container` at 20% opacity with a `tertiary` icon and text to signify "Verified Seller."
- **Price Tag:** Large `headline-sm` typography with the `secondary` (#34618d) color to ensure the price feels authoritative but not aggressive.

---

## 6. Do’s and Don’ts

### Do
- **Do** use asymmetric margins. Let an image be 40px from the left while text is 80px from the left to create an editorial "magazine" feel.
- **Do** use `display-lg` for empty states. Make "No items found" look like a design statement, not an error.
- **Do** leverage the `secondary-fixed-dim` for background accents in dark mode to keep the "Trust Blue" present even in low light.

### Don't
- **Don't** use pure black #000000. Even in dark mode, our scaffold is #121212 to maintain a soft, premium "ink" feel.
- **Don't** use a divider line between list items. If the content isn't distinct enough to stand without a line, use a background color shift.
- **Don't** use standard 400ms easing. Use custom "Cubic Bezier (0.23, 1, 0.32, 1)" for all transitions to give a "snappy yet weighted" luxury feel.
