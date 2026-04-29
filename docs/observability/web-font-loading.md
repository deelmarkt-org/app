# Web Font Loading Strategy

> Closes PLAN-frontend-launch.md Phase 1 Step 9 (FOUT validation).
> Owner: pizmam · Last verified: 2026-04-29

## TL;DR

DeelMarkt has **zero FOUT (Flash of Unstyled Text) risk** on web. Plus Jakarta Sans
is bundled as an app asset, not loaded from a CDN. Flutter Web's renderer
references the font from the asset bundle, so first-paint uses the brand
typeface immediately — no system-font fallback flash.

## Verification

| Check | Source of Truth | Status |
| :--- | :--- | :--- |
| Font is in `pubspec.yaml` `fonts:` block | `pubspec.yaml:134-139` | ✅ Pass |
| Variable font + italic variant assets exist | `assets/fonts/PlusJakartaSans-Variable.ttf`, `PlusJakartaSans-Italic-Variable.ttf` | ✅ Pass |
| No `<link rel="stylesheet" href="https://fonts.googleapis.com/...">` in `web/index.html` | `web/index.html` (full file) | ✅ Pass |
| No `@import url(https://fonts.googleapis.com/...)` in any CSS | repo-wide grep | ✅ Pass |
| CanvasKit renderer reads font from asset bundle | Flutter Web default behavior | ✅ Pass |

## Why bundled fonts win for Flutter Web

Flutter Web with the CanvasKit renderer (default in production builds) uses
`Skia` to paint glyphs directly — it does not delegate text rendering to the
browser's CSS pipeline. The font is loaded once when the asset bundle initializes
and is available for the first frame.

If a font were loaded from a CDN via `<link>`, two failure modes appear:

1. **FOUT** — system font renders first, then the page reflows when the CDN font
   arrives. Layout shift hurts CLS (Core Web Vital).
2. **FOIT** — invisible text until the CDN font arrives (Safari default at the time
   of writing). Worse for perceived performance.

Bundling avoids both.

## Trade-offs of the bundled approach

| Trade-off | Mitigation |
| :--- | :--- |
| Larger initial download (~280 KB for the variable font) | Variable font ships all weights in one file — smaller than 4 individual `.ttf`s. Service Worker caches it after first visit. |
| Cannot lazy-load weights | Variable font already covers 200–800 weight range, so no separate file per weight needed. |
| App version bump required to update font | Acceptable — fonts rarely change. Trade lock-in for guaranteed first-paint quality. |

## Follow-ups (non-blocking)

- **CSP cleanup (P3 / LOW)** — `web/index.html` line 37 CSP includes
  `https://fonts.gstatic.com` in `font-src` and `connect-src`. Since no font is
  loaded from this origin, removing it tightens the policy. Defer to a separate
  PR with belengaz (CSP changes need DevOps review).
- **`<link rel="preconnect">` not needed** — would only matter for CDN-hosted
  fonts. Current setup serves font from same-origin asset bundle.

## Test coverage

Bundled-font behavior is implicitly tested by every widget golden test that
asserts text appearance. No additional automated test required for FOUT itself
(the failure mode would manifest as a CDN request that we can verify is absent).

## Related

- `PLAN-frontend-launch.md` §Phase 1 Step 9 (font loading strategy + Risk Register row "Font FOUT risk")
- `pubspec.yaml` `fonts:` declaration
- `assets/fonts/` font asset directory
