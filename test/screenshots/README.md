# Screenshot Pipeline

Generates App Store (iOS) and Play Console (Android) screenshots for all
hero screens × 2 locales (NL, EN) × 2 themes (light, dark) × 6 device
classes.

---

## Quick Start

### Generate (update goldens)
```bash
flutter test --update-goldens test/screenshots/drivers/
```

PNGs land in `test/screenshots/drivers/goldens/`.

### Verify (compare against committed goldens)
```bash
flutter test test/screenshots/drivers/
```

Fails if any screenshot differs from the committed golden.

### Inventory broken light/dark pairs (issue #203)
```bash
dart run scripts/check_quality.dart --check-goldens
```

Reports each `{screen}_{locale}_{device}` whose committed light and dark
PNGs are byte-identical — a fingerprint of solid-color pre-paint capture
(see [Known Issues](#known-issues)).

### Copy to Fastlane
After generating, organize into the Fastlane directory structure:
```bash
bash scripts/screenshots_to_fastlane.sh
```

---

## Matrix

| Dimension | Values |
|:----------|:-------|
| Locales | `nl_NL`, `en_US` |
| Themes | `light`, `dark` |
| Devices | `ios_67`, `ios_65`, `ios_55`, `ios_ipad_129`, `android_phone`, `android_tablet`, `desktop_1400` |

---

## Device Sizes

| ID | Label | Logical size | DPR | Physical |
|:---|:------|:-------------|:----|:---------|
| `ios_67` | iPhone 6.7" | 430×932 | 3× | 1290×2796 |
| `ios_65` | iPhone 6.5" | 414×896 | 3× | 1242×2688 |
| `ios_55` | iPhone 5.5" | 414×736 | 3× | 1242×2208 |
| `ios_ipad_129` | iPad 12.9" | 1024×1366 | 2× | 2048×2732 |
| `android_phone` | Android Phone | 412×915 | 2.625× | ~1080×2400 |
| `android_tablet` | Android Tablet | 800×1280 | 2× | 1600×2560 |
| `desktop_1400` | Web (desktop) | 1400×900 | 1× | 1400×900 |

---

## Known Issues

### #203 — solid-color pre-paint capture for async-built screens

`captureScreenshot` currently takes the golden frame before async
providers (Riverpod `AsyncNotifier.build()` chains, EasyLocalization asset
loads, mock-repository `Future.delayed`) resolve. The result is a
solid-color frame whose bytes are byte-identical between light and dark
themes — easy to detect via the `--check-goldens` gate above.

**Status:** open. Tracked in
[issue #203](https://github.com/deelmarkt-org/app/issues/203).

**Workaround:** desktop screenshot drivers added under #193 (PRs #208,
#209, #210) ship light-theme only with a `// TODO(#203)` comment that
re-enables `ScreenshotTheme.values` once the capture-infra fix lands.

**Diagnostic baseline:** the canary test in
`drivers/chat_thread_screenshot_test.dart` runs the same pump path and
asserts the widget tree is in a loaded state (`> 50` widgets) after
capture. It is currently `skip`-marked — pending #203 it will flip GREEN
when a working pump fix is shipped.

---

## CI

The `.github/workflows/screenshots.yml` workflow runs on every PR that
touches `lib/` UI files. It uses the `macos-14` runner (required for font
consistency — see `PLAN-p43-aso.md` §D-1).

CI pipeline steps:
1. `flutter test --update-goldens` — regenerate PNGs
2. Verify expected PNG count
3. `dart run scripts/check_quality.dart --check-goldens` — solid-color
   inventory (warn-only until #203 lands)
4. Auto-commit regenerated PNGs back to the PR branch
5. Upload screenshot artefacts

Screenshots are stored in Git LFS
(see `fastlane/screenshots/**` in `.gitattributes`).

---

## Seed Data

All screenshots use mock repositories (`useMockDataProvider = true`) with
deterministic fictitious data. See `_support/seed_data.dart`.

**Security:** Seed data uses `@example.invalid` emails and fictional Dutch
addresses. Never replace with real user data — CI OCR scanner will fail.

---

## Adding a New Screen

1. Create `test/screenshots/drivers/<screen_name>_screenshot_test.dart`
2. Follow the pattern in `home_buyer_screenshot_test.dart`
3. Add the new test to `integration_test/screenshots_test.dart`
4. Run `--update-goldens` to generate initial PNGs
5. Commit both the test + the goldens (LFS tracked)
