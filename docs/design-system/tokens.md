# Design Tokens

> Colours, typography, spacing, radius, elevation, dark mode, animation.
> All values implemented in `lib/core/design_system/`.

---

## Brand Voice (for UI microcopy)

| Trait | Do | Don't |
|:------|:---|:------|
| Friendly | "Bijna klaar!" | "Stap 3 van 4" |
| Helpful errors | "Dat lukte niet — probeer opnieuw" | "Ongeldige invoer" |
| Celebratory | "Verkocht! 🎉" | "Transactie voltooid" |
| Slightly playful | Emoji in categories, Lottie on success | Childish, gimmicky, distracting |

All UI text in NL + EN. Never hardcode strings.

---

## Colours

### Primary

| Token | Hex | RGB | Usage |
|:------|:----|:----|:------|
| `primary` | `#F15A24` | 241,90,36 | Brand orange, CTAs, FAB, active |
| `primary-light` | `#FF8A5C` | 255,138,92 | Hover/pressed |
| `primary-surface` | `#FFF3EE` | 255,243,238 | Selected chips, tinted backgrounds |
| `secondary` | `#1E4F7A` | 30,79,122 | Headers, links, trust badges |
| `secondary-light` | `#2D6FA3` | 45,111,163 | Hover states |
| `secondary-surface` | `#EAF5FF` | 234,245,255 | Info banners |

### Semantic

| Token | Hex | Surface Hex | Usage |
|:------|:----|:------------|:------|
| `success` | `#2EAD4A` | `#E8F8EC` | Verified, escrow released, eco |
| `warning` | `#FFC857` | `#FFF8E6` | Pending, escrow held |
| `error` | `#E53E3E` | `#FDE8E8` | Scam alerts, failed, destructive |
| `info` | `#3B82F6` | `#EFF6FF` | Notices, tooltips |

### Neutral

| Token | Hex | Usage |
|:------|:----|:------|
| `neutral-900` | `#1A1A1A` | Primary text |
| `neutral-700` | `#555555` | Secondary text |
| `neutral-500` | `#8A8A8A` | Placeholder, disabled |
| `neutral-300` | `#D1D5DB` | Borders, dividers |
| `neutral-200` | `#E5E5E5` | Input borders, card strokes |
| `neutral-100` | `#F3F4F6` | Subtle backgrounds |
| `neutral-50` | `#F8F9FB` | Scaffold background |
| `neutral-0` | `#FFFFFF` | Cards, modals, inputs |

### Trust (dedicated — never for general UI)

| Token | Hex | Usage |
|:------|:----|:------|
| `trust-verified` | `#16A34A` | iDIN verified badge |
| `trust-escrow` | `#2563EB` | Escrow protection banner + **completed** steps in the escrow timeline. Active steps use `primary` orange per `patterns.md` §Escrow Timeline. |
| `trust-warning` | `#DC2626` | Scam detection alerts |
| `trust-pending` | `#F59E0B` | KYC pending |
| `trust-shield` | `#F0FDF4` | Badge background |

### Flutter Implementation

```dart
class DeelmarktColors {
  static const primary = Color(0xFFF15A24);
  static const primaryLight = Color(0xFFFF8A5C);
  static const primarySurface = Color(0xFFFFF3EE);
  static const secondary = Color(0xFF1E4F7A);
  static const secondaryLight = Color(0xFF2D6FA3);
  static const secondarySurface = Color(0xFFEAF5FF);

  static const success = Color(0xFF2EAD4A);
  static const successSurface = Color(0xFFE8F8EC);
  static const warning = Color(0xFFFFC857);
  static const warningSurface = Color(0xFFFFF8E6);
  static const error = Color(0xFFE53E3E);
  static const errorSurface = Color(0xFFFDE8E8);

  static const neutral900 = Color(0xFF1A1A1A);
  static const neutral700 = Color(0xFF555555);
  static const neutral500 = Color(0xFF8A8A8A);
  static const neutral300 = Color(0xFFD1D5DB);
  static const neutral200 = Color(0xFFE5E5E5);
  static const neutral100 = Color(0xFFF3F4F6);
  static const neutral50 = Color(0xFFF8F9FB);
  static const white = Color(0xFFFFFFFF);

  static const trustVerified = Color(0xFF16A34A);
  static const trustEscrow = Color(0xFF2563EB);
  static const trustWarning = Color(0xFFDC2626);
  static const trustPending = Color(0xFFF59E0B);
  static const trustShield = Color(0xFFF0FDF4);
}
```

### Contrast Note

Primary orange `#F15A24` on white = 3.4:1 — only for large text (≥18.66px bold or ≥24px). For small text, use white-on-orange or secondary blue.

---

## Typography

**Font:** Plus Jakarta Sans (SIL OFL, free commercial)
**Fallback:** `'Plus Jakarta Sans', 'Inter', system-ui, sans-serif`
**Monospace:** JetBrains Mono (code display only)

| Token | Size | Weight | Height | Tracking | Usage |
|:------|:-----|:-------|:-------|:---------|:------|
| `display` | 32px | Bold 700 | 1.25 | -0.02em | Hero, onboarding |
| `heading-lg` | 24px | Bold 700 | 1.33 | -0.01em | Page titles |
| `heading-md` | 20px | SemiBold 600 | 1.4 | 0 | Card titles, modals |
| `heading-sm` | 18px | SemiBold 600 | 1.33 | 0 | Subsections |
| `body-lg` | 16px | Regular 400 | 1.5 | 0 | Primary body |
| `body-md` | 14px | Regular 400 | 1.43 | 0 | Secondary, metadata |
| `body-sm` | 12px | Medium 500 | 1.33 | 0.01em | Captions, badges |
| `label` | 14px | SemiBold 600 | 1.43 | 0.01em | Buttons, form labels |
| `price` | 20px | Bold 700 | 1.2 | 0 | Listing price |
| `price-sm` | 16px | Bold 700 | 1.25 | 0 | Card price |
| `overline` | 11px | SemiBold 600 | 1.45 | 0.08em | Category labels, badges (UPPERCASE) |

**Price rules:** Tabular figures (`FontFeature.tabularFigures()`). Euro precedes: `€12,50`. Comma decimal (Dutch). BTW status mandatory on totals.

```dart
class DeelmarktTypography {
  static const fontFamily = 'PlusJakartaSans';

  static TextTheme textTheme = const TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: -0.64),
    headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.33, letterSpacing: -0.24),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4),
    headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.33),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.43),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.33, letterSpacing: 0.12),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.43, letterSpacing: 0.14),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.45, letterSpacing: 0.88),
  );

  static const TextStyle price = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.2);
  static const TextStyle priceSm = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.25);
}
```

---

## Spacing

**Base unit: 4px.** All spacing is a multiple of 4.

| Token | px | Usage |
|:------|:---|:------|
| `s1` | 4 | Inline, icon-to-text gap |
| `s2` | 8 | Tight padding, related elements |
| `s3` | 12 | Card padding, list item gap |
| `s4` | 16 | Section padding, standard gap |
| `s5` | 20 | Medium separation |
| `s6` | 24 | Between content groups |
| `s8` | 32 | Section separation |
| `s10` | 40 | Large section breaks |
| `s12` | 48 | Page-level vertical padding |
| `s16` | 64 | Hero/splash spacing |

**Screen margins:** Mobile 16px, Tablet 24px, Desktop max-width 1200px centred.

```dart
class Spacing {
  static const double s1 = 4, s2 = 8, s3 = 12, s4 = 16, s5 = 20;
  static const double s6 = 24, s8 = 32, s10 = 40, s12 = 48, s16 = 64;
  static const double screenMarginMobile = 16, screenMarginTablet = 24;
  static const double listingCardGap = 12, sectionGap = 32;
}
```

---

## Border Radius

| Token | px | Usage |
|:------|:---|:------|
| `xxs` | 2 | Strength indicator segments |
| `xs` | 6 | Small badges, tags |
| `sm` | 8 | Chips, small buttons |
| `md` | 10 | Inputs, text fields |
| `lg` | 12 | Buttons, images |
| `xl` | 16 | Cards, modals, bottom sheets |
| `xxl` | 24 | Large containers |
| `full` | 999 | Avatars, pills |

```dart
class DeelmarktRadius {
  static const xxs = 2.0, xs = 6.0, sm = 8.0, md = 10.0, lg = 12.0;
  static const xl = 16.0, xxl = 24.0, full = 999.0;
}
```

---

## Elevation

Cards use **border strokes** (no shadow). Shadows for floating elements only.

| Level | Usage | Shadow |
|:------|:------|:-------|
| 0 | Cards, inputs | No shadow; 1px border `neutral-200` |
| 1 | Sticky headers | `0 1px 3px rgba(0,0,0,0.08)` |
| 2 | Dropdowns, popovers | `0 4px 12px rgba(0,0,0,0.1)` |
| 3 | Modals, bottom sheets | `0 8px 24px rgba(0,0,0,0.12)` |
| 4 | FAB | `0 12px 32px rgba(0,0,0,0.15)` |

```dart
class DeelmarktShadows {
  static const elevation1 = [BoxShadow(offset: Offset(0, 1), blurRadius: 3, color: Color(0x14000000))];
  static const elevation2 = [BoxShadow(offset: Offset(0, 4), blurRadius: 12, color: Color(0x1A000000))];
  static const elevation3 = [BoxShadow(offset: Offset(0, 8), blurRadius: 24, color: Color(0x1F000000))];
  static const elevation4 = [BoxShadow(offset: Offset(0, 12), blurRadius: 32, color: Color(0x26000000))];
}
```

---

## Dark Mode

| Token | Light | Dark |
|:------|:------|:-----|
| Scaffold | `#F8F9FB` | `#121212` |
| Card surface | `#FFFFFF` | `#1E1E1E` |
| Elevated surface | `#FFFFFF` | `#2C2C2C` |
| Primary text | `#1A1A1A` | `#F2F2F2` |
| Secondary text | `#555555` | `#A0A0A0` |
| Border | `#E5E5E5` | `#333333` |
| Divider | `#E5E5E5` | `#2C2C2C` |
| Primary orange | `#F15A24` | `#FF7A4D` |
| Secondary blue | `#1E4F7A` | `#5BA3D9` |
| Success | `#2EAD4A` | `#4ADE80` |
| Error | `#E53E3E` | `#F87171` |
| Warning | `#FFC857` | `#FFC857` (unchanged) |
| Trust shield bg | `#F0FDF4` | `#052E16` |
| Error surface | `#FDE8E8` | `#450A0A` |
| Info surface | `#EFF6FF` | `#172554` |

**Rules:**
- System preference by default; manual override in settings
- Images never dimmed (listings must show true colour)
- Elevation in dark uses lighter surface tones, not shadows
- Shimmer: `#2C2C2C` → `#3C3C3C` gradient
- All contrast ratios re-validated for dark palette

---

## Breakpoints

| Token | Range | Grid Columns | Layout |
|:------|:------|:-------------|:-------|
| `compact` | < 600px | 2 | Mobile (bottom nav) |
| `medium` | 600–840px | 3 | Tablet portrait (bottom nav) |
| `expanded` | 840–1200px | 4 | Tablet landscape (side rail) |
| `large` | > 1200px | 4–5 + sidebar | Desktop (nav drawer) |

**Adaptive patterns:**

| Pattern | Compact | Medium+ |
|:--------|:--------|:--------|
| Navigation | Bottom nav | Side rail / drawer |
| Listing grid | 2 columns | 3–5 columns |
| Listing detail | Full screen | Master-detail split |
| Chat | Full screen | Split view (list + thread) |
| Filters | Bottom sheet | Side panel |

```dart
class Breakpoints {
  static const compact = 600.0, medium = 840.0, expanded = 1200.0;
  static bool isCompact(BuildContext c) => MediaQuery.sizeOf(c).width < compact;
  static bool isExpanded(BuildContext c) => MediaQuery.sizeOf(c).width >= medium;
}
```

---

## Animation

| Type | Duration | Easing |
|:-----|:---------|:-------|
| Standard | 200ms | `Curves.easeOutCubic` (entrances) |
| Complex | 300ms | `Curves.easeOutCubic` |
| Exit | — | `Curves.easeInCubic` |
| Max allowed | 400ms | — |

### Animation Inventory

| Interaction | Animation | Duration | Package |
|:------------|:----------|:---------|:--------|
| Favourite tap | Heart scale + fill + burst | 300ms | Lottie |
| Listing card tap | Hero image expand to detail | 300ms | `Hero` widget |
| "Verkocht!" | Checkmark draw + confetti | 800ms | Lottie |
| Pull-to-refresh | Logo spin | Variable | `RefreshIndicator` |
| Page transition | Shared axis (horizontal) | 300ms | `PageRouteBuilder` |
| Bottom sheet | Slide up + fade backdrop | 250ms | `showModalBottomSheet` |
| Offer sent | Bubble fly-in | 200ms | `AnimatedContainer` |
| Escrow step complete | Circle fill + line draw | 400ms | Custom painter |
| Skeleton loading | Shimmer sweep | 1500ms loop | `shimmer` package |
| Tab switch | Cross-fade | 200ms | `AnimatedSwitcher` |

**Reduced motion:** Respect `MediaQuery.disableAnimations`. When true: all durations = `Duration.zero` (WCAG 2.2).
