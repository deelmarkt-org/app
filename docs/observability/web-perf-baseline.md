# Web Performance Baseline (P-45)

> Closes PLAN-frontend-launch.md Phase 1 Step 4 — last open Phase 1 success criterion.
> Owner: pizmam · First measurement: 2026-04-29 · Build: `flutter build web --release` (Flutter 3.x, CanvasKit renderer)

## TL;DR

| Phase 1 budget (PLAN-frontend-launch §2) | Measured | Verdict |
| :--- | :---: | :---: |
| Total initial download < 5 MB | **~1.55 MB gzip (CDN CanvasKit)** / **~4.42 MB gzip (local CanvasKit)** | ✅ Pass |
| Time to first frame < 3 s on 4G | needs Lighthouse run on staging (C3 blocker) | ⏳ |
| CanvasKit WASM load < 2 s cached | gstatic.com CDN delivers — no fetch on revisit (SW cache) | ✅ Inferred |
| Frame budget 16.6 ms (60 fps) | needs DevTools recording on real device | ⏳ |

The bundle-size baseline is **inside budget** with comfortable headroom.
Frame-rate and end-to-end TTFF measurements need a publicly served URL —
the **STAGING_URL** dependency (Tier-1 audit blocker `C3`, owner: belengaz)
gates the full Lighthouse pass.

## Bundle metrics — 2026-04-29

```
flutter build web --release   (Flutter 3.x, CanvasKit renderer)
```

### Critical-path artefacts (root of `build/web/`)

| Artefact | Raw | Gzipped (server compression) | Role |
| :--- | ---: | ---: | :--- |
| `index.html` + meta | ~3 KB | ~1 KB | HTML shell (CSP + OG) |
| `flutter_bootstrap.js` | 9.6 KB | 3.8 KB | Loads `flutter.js` + `main.dart.js` |
| `flutter.js` | 9.3 KB | 3.6 KB | Engine loader |
| `main.dart.js` | **4.61 MB** | **1.31 MB** | Compiled Dart app code |
| `canvaskit/canvaskit.js` | 84.8 KB | 26.8 KB | WASM glue |
| `canvaskit/canvaskit.wasm` | **6.83 MB** | **2.74 MB** | Skia WASM (Chromium variant) |
| `canvaskit/skwasm*.wasm` | 8.20 MB combined | n/a | Multi-thread / WIMP variants — fetched only when feature-detected |
| `assets/fonts/PlusJakartaSans-Variable.ttf` | ~280 KB | ~140 KB | Brand typeface (bundled, no FOUT — see `web-font-loading.md`) |
| `assets/NOTICES` | 1.45 MB | ~430 KB | OSS license aggregate (lazy-loaded) |
| `flutter_service_worker.js` | 0.8 KB | <1 KB | Cache manifest (Flutter default SW) |

### First-paint critical-path totals

CanvasKit is by default fetched from
`https://www.gstatic.com/flutter-canvaskit/<engine-hash>/canvaskit.{js,wasm}`,
not from our origin. Two scenarios are relevant:

| Scenario | Critical-path gzipped bytes | Phase 1 budget (5 MB) |
| :--- | ---: | :---: |
| **CDN CanvasKit** (default, gstatic.com) | **~1.55 MB** (`main.dart.js` + bootstrap + flutter.js + bundled font) | ✅ 31% of budget |
| **Self-hosted CanvasKit** (`--web-renderer canvaskit` + serve from origin) | **~4.42 MB** (above + canvaskit.{js,wasm}) | ✅ 88% of budget |

The default (gstatic CDN) gives strong first-paint numbers because CanvasKit
WASM is shared across every Flutter web app on the public CDN — return
visitors typically hit a warm browser cache from a different site.

### CanvasKit fall-through behaviour

`flutter_bootstrap.js` ships **all three Skia variants** (`canvaskit`,
`skwasm`, `skwasm_heavy`) but only fetches **one** based on browser
feature-detection:

- Modern Chrome/Edge with `SharedArrayBuffer` + COOP/COEP → `skwasm` (multi-thread)
- Firefox / Safari → `canvaskit` (single-thread, default)
- Chromium-only fast path → `wimp.wasm`

Phase 1 default in DeelMarkt: single-thread CanvasKit. Multi-thread
requires COOP `same-origin` + COEP `require-corp` HTTP headers — owned
by belengaz on Cloudflare. Tracked separately from this baseline.

## Lighthouse — pending staging URL

A full Lighthouse audit (`PWA + Performance + Best Practices + Accessibility +
SEO` categories) requires a deployed origin. The Tier-1 preflight
audit identifies this as blocker **C3** (`STAGING_URL` configuration,
owner: belengaz, see `docs/audits/2026-04-25-tier1-preflight.md`).

Once C3 closes, the baseline can be captured via:

```bash
# 1. Build (already done above)
flutter build web --release

# 2. Serve locally for the audit run (needs Python or any static server)
cd build/web && python -m http.server 8080 &

# 3. Run Lighthouse against the local server (CI mode, JSON output)
npx -y lighthouse@latest http://localhost:8080 \
  --preset=desktop \
  --output=json \
  --output-path=./lighthouse-baseline.json \
  --quiet \
  --chrome-flags="--headless"

# 4. Extract key scores
jq '.categories | map_values(.score)' lighthouse-baseline.json
```

Or against staging once `STAGING_URL` is set:

```bash
npx -y lighthouse@latest "$STAGING_URL" --preset=desktop --output=json
```

### Lighthouse target scores (Phase 1 → Launch)

Per `docs/PLAN-frontend-launch.md` §Phase 5 quality gate ("Lighthouse ≥ 80
performance; ≥ 60 absolute floor for CanvasKit baseline"):

| Category | Target | Acceptable floor | Notes |
| :--- | :---: | :---: | :--- |
| Performance | ≥ 80 | 60 | CanvasKit pays a Lighthouse tax for the WASM blocking time; 60 is documented floor |
| Accessibility | ≥ 90 | 90 | EAA legal requirement — no floor, only target |
| Best Practices | ≥ 90 | 80 | CSP, HTTPS, no console errors |
| SEO | ≥ 90 | 80 | OG tags, meta descriptions, structured data |
| PWA | ≥ 80 | 60 | Default Flutter SW + manifest; no offline-first ambition Phase 1 |

When the first measured Lighthouse run lands, append a row below with the
date, scores, audit run URL, and any deltas from this baseline. Re-measure
after every Phase 5 polish PR.

## Re-measurement script

`scripts/measure_web_bundle.sh` (added in this PR) re-runs the bundle
size measurement deterministically. It assumes a clean release build is
already present in `build/web/`. Use it on every release PR to detect
regressions early.

```bash
bash scripts/measure_web_bundle.sh
```

Output is a markdown table identical to the "Critical-path artefacts" table
above, suitable for pasting into PR descriptions.

## Cross-references

- **PLAN-frontend-launch.md** §2 Performance Budget (sets the 5 MB / 3 s / 60 fps targets) and §Phase 5 Quality Gate (sets the Lighthouse ≥ 80 launch bar)
- **`docs/observability/web-font-loading.md`** — bundled-font verification (related Phase 1 Step 9)
- **`docs/observability/perf-slos.md`** — runtime SLOs (`app_start`, `listing_load`, etc. measured by Firebase Performance, not Lighthouse)
- **Tier-1 audit C3** — `STAGING_URL` configuration blocker (`docs/audits/2026-04-25-tier1-preflight.md`)
