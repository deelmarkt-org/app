# Design System Preamble — Prepend to ALL screen prompts

> Copy this preamble before every screen-specific prompt to ensure consistency.
> Values sourced from docs/design-system/tokens.md, components.md, accessibility.md.
> Last verified: 2026-03-27

---

## Preamble (copy this before every prompt)

```
CONTEXT: You are designing screens for "DeelMarkt" — a trust-first Dutch
peer-to-peer marketplace app (like Vinted meets Stripe). The app runs on
iOS, Android, AND web (Flutter). Every screen must be responsive and work
across all platforms.

BRAND IDENTITY:
- Positioning: "De eerlijke marktplaats van Nederland" (The fair marketplace)
- Tone: trustworthy, modern, premium — NOT a classified ads site
- Trust is the #1 differentiator: escrow protection, verified sellers, badges
- Target: Dutch consumers 18-45, tech-comfortable, value-conscious
- Voice: friendly ("Bijna klaar!"), helpful errors ("Dat lukte niet — probeer opnieuw"),
  celebratory ("Verkocht!"), slightly playful (emoji in categories, Lottie on success)

DESIGN SYSTEM — follow these EXACTLY (from docs/design-system/tokens.md):

Colors:
- Primary: #F15A24 (orange) — CTAs, FAB, active states, brand
- Primary hover: #FF8A5C
- Primary surface: #FFF3EE (selected chips, tinted backgrounds)
- Secondary: #1E4F7A (blue) — headers, links, trust badges, small text links
- Secondary surface: #EAF5FF (info banners)
- Success: #2EAD4A — verified badges, escrow released, eco
- Success surface: #E8F8EC
- Warning: #FFC857 — pending states, escrow held
- Warning surface: #FFF8E6
- Error: #E53E3E — scam alerts, destructive actions
- Error surface: #FDE8E8
- Trust Verified: #16A34A (iDIN verified badge — dedicated, never for general UI)
- Trust Escrow: #2563EB (escrow active indicator)
- Trust Warning: #DC2626 (scam detection alerts)
- Trust Pending: #F59E0B (KYC pending)
- Trust Shield bg: #F0FDF4

Neutrals:
- neutral-900: #1A1A1A (primary text)
- neutral-700: #555555 (secondary text)
- neutral-500: #8A8A8A (placeholder, disabled)
- neutral-300: #D1D5DB (borders, dividers)
- neutral-200: #E5E5E5 (input borders, card strokes)
- neutral-100: #F3F4F6 (subtle backgrounds)
- neutral-50: #F8F9FB (scaffold background)
- white: #FFFFFF (cards, modals, inputs)

CONTRAST RULE: Primary orange #F15A24 on white = 3.4:1 — ONLY for text
>= 18.66px bold or >= 24px regular. For small text links use secondary blue
#1E4F7A. For buttons: white text ON orange background.

Typography (Plus Jakarta Sans — all weights):
- display: 32px Bold 700, height 1.25, tracking -0.02em (hero, onboarding)
- heading-lg: 24px Bold 700, height 1.33, tracking -0.01em (page titles)
- heading-md: 20px SemiBold 600, height 1.4 (card titles, modals)
- heading-sm: 18px SemiBold 600, height 1.33 (subsections)
- body-lg: 16px Regular 400, height 1.5 (primary body text)
- body-md: 14px Regular 400, height 1.43 (secondary, metadata)
- body-sm: 12px Medium 500, height 1.33, tracking 0.01em (captions, badges)
- label: 14px SemiBold 600, height 1.43, tracking 0.01em (buttons, form labels)
- price: 20px Bold 700, height 1.2 (listing price — tabular figures)
- price-sm: 16px Bold 700, height 1.25 (card price — tabular figures)
- overline: 11px SemiBold 600, height 1.45, tracking 0.08em, UPPERCASE (category labels)

Price formatting: Euro precedes amount, comma decimal (Dutch): "€ 12,50"
Tabular figures (monospaced numbers) for all prices.
BTW status mandatory on payment totals.

Spacing (base unit: 4px, all multiples of 4):
- s1: 4px (inline, icon-to-text)
- s2: 8px (tight padding, related elements)
- s3: 12px (card padding, list item gap)
- s4: 16px (section padding, standard gap)
- s5: 20px (medium separation)
- s6: 24px (between content groups)
- s8: 32px (section separation)
- s10: 40px (large section breaks)
- s12: 48px (page-level vertical padding)
- s16: 64px (hero/splash spacing)
- Screen margins: 16px mobile, 24px tablet, max-width 1200px desktop (centered)
- Listing card gap: 12px

Radius:
- xs: 6px (small badges, tags)
- sm: 8px (chips, small buttons, inputs)
- md: 10px (text fields)
- lg: 12px (buttons, images)
- xl: 16px (cards, modals, bottom sheets)
- xxl: 24px (large containers)
- full: 999px (avatars, pills)

Elevation (cards use BORDERS, not shadows):
- Level 0: No shadow, 1px border neutral-200 (cards, inputs)
- Level 1: 0 1px 3px rgba(0,0,0,0.08) (sticky headers)
- Level 2: 0 4px 12px rgba(0,0,0,0.1) (dropdowns)
- Level 3: 0 8px 24px rgba(0,0,0,0.12) (modals, bottom sheets)
- Level 4: 0 12px 32px rgba(0,0,0,0.15) (FAB only)

Components (from docs/design-system/components.md):

Buttons:
- Primary: filled #F15A24, white text, radius lg (12px)
- Secondary: filled #1E4F7A, white text
- Outline: transparent bg, 1.5px #1E4F7A border, #1E4F7A text
- Ghost: transparent, #555555 text
- Destructive: filled #E53E3E, white text
- Success: filled #2EAD4A, white text
- Sizes: Large 52px, Medium 44px, Small 36px
- Button text: sentence case ONLY ("Account aanmaken", NEVER "ACCOUNT AANMAKEN")
- 5 states: default, pressed (10% darker), focused (2px primary outline), disabled (40% opacity), loading (spinner)
- FAB (Sell): Orange, centered in bottom nav, radius xl (16px), elevation 4

Listing Card (grid):
- Image: 4:3 ratio (NOT 16:9)
- Favourite heart: 44x44 tap target, top-right overlay
- Trust badge overlay: small shield, bottom-left of image
- Below image: price-sm bold FIRST, then title (max 2 lines), location + distance, "Escrow beschikbaar"
- Card: 1px neutral-200 border, radius xl (16px), NO shadow
- Shimmer skeleton while loading

Navigation:
- Bottom bar (compact): 5 items — Home, Zoeken, Verkopen, Berichten, Profiel
- NavigationRail (expanded >= 840px): same 5 items, vertical, 72px width
- Active: filled icon + primary color, label bold
- Inactive: outlined icon + neutral-500, label regular
- FAB "Verkopen" (+) centered in bottom nav, always visible, never hidden on scroll

Icons: Phosphor Icons (thin/regular weight) — NOT Material Icons
- 24px default, 20px compact, 48px feature illustrations

RESPONSIVE — every screen must show:
1. Compact (< 600px): Mobile — single column, bottom nav bar, 16px margins
2. Medium (600-840px): Tablet — bottom nav, wider cards, 24px margins
3. Expanded (>= 840px): Desktop — NavigationRail (72px), multi-column, max 1200px centered

Grid columns per breakpoint:
- Compact: 4 columns (listing cards: 2 per row)
- Medium: 8 columns (listing cards: 3 per row)
- Expanded: 12 columns (listing cards: 4-5 per row)

DARK MODE — every screen must have a dark variant:
- Scaffold: #121212
- Card surface: #1E1E1E with 1px #333333 border
- Elevated surface: #2C2C2C
- Primary text: #F2F2F2
- Secondary text: #A0A0A0
- Border: #333333
- Primary orange: #FF7A4D (slightly lighter for dark bg contrast)
- Secondary blue: #5BA3D9
- Success: #4ADE80
- Error: #F87171
- Trust shield bg: #052E16
- Shimmer: #2C2C2C → #3C3C3C
- Images never dimmed (show true product colors)

STATES — every screen must account for:
- Loading: skeleton shimmer (light: neutral-100 → white pulse, dark: #2C2C2C → #3C3C3C)
- Error: ErrorState widget (red icon + friendly message + "Opnieuw proberen" retry button)
- Empty: EmptyState widget (flat illustration + message + CTA button)
- Data: normal content state

ACCESSIBILITY (WCAG 2.2 AA — European Accessibility Act, legally required):
- Touch targets: ALL interactive elements >= 44x44px, >= 8px spacing between
- Contrast: 4.5:1 normal text, 3:1 large text
- Focus: 2px primary outline, 2px offset on all focusable elements
- Semantics labels: NL + EN on all interactive widgets
- Reduced motion: respect MediaQuery.disableAnimations
- Redundant entry: auto-fill addresses, saved payment, postcode → city

ANTI-PATTERNS — do NOT do these:
- No gradients (flat design only)
- No heavy drop shadows (subtle 1px borders for cards instead)
- No stock photography for illustrations (use flat/minimal art)
- No generic "AI slop" aesthetic (bubbly, glowy, over-rounded)
- No Material Design 3 default look — must feel custom and premium
- No emoji in body text (okay in category labels per brand voice)
- No ALL CAPS on buttons (sentence case: "Account aanmaken")
- No raw TextStyle — all typography from design system tokens
- No hardcoded colors — all from token palette

LANGUAGE:
- Primary: Dutch (NL), with English (EN) equivalent available
- Dutch UI terms:
  Zoeken = Search, Verkopen = Sell, Berichten = Messages, Profiel = Profile
  Kopen = Buy, Bericht sturen = Send message, Favorieten = Favourites
  Categorieën = Categories, Instellingen = Settings
  Laden... = Loading, Opnieuw proberen = Try again
  Dat lukte niet = That didn't work, Bijna klaar! = Almost done!

OUTPUT FORMAT:
- High-fidelity UI mockup
- Mobile: iPhone 15 Pro frame (1290x2796px)
- Desktop: Browser window (1440x900px) or MacBook frame
- Show BOTH compact (mobile) and expanded (desktop) for every screen
- Show realistic Dutch marketplace content (not lorem ipsum)
- Show light mode as primary, dark mode as variation
```

---

## How to use

For each screen prompt:

1. Start with: `[paste preamble above]`
2. Then add: `SCREEN-SPECIFIC DESIGN:` followed by the screen's layout and content
3. End with: `VARIATIONS NEEDED:` listing specific states/modes

This ensures every screen shares the same visual DNA.
