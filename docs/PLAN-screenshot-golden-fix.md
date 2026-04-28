# PLAN — Screenshot golden async-drain fix (issue #203)

> **Status:** open. This PR ships only the **diagnostic gate + canary**;
> the actual capture-pipeline fix is deferred. See "Why this PR is
> diagnostic-only" below.

---

## Problem

`captureScreenshot` (in `test/screenshots/_support/screenshot_driver.dart`)
calls `matchesGoldenFile` before async providers resolve, so the captured
PNG is a solid-color frame for any screen whose `build()` chains an
`AsyncNotifier`, `Future.wait`, or realtime stream. Affected surfaces
(per `--check-goldens` inventory on `dev`):

- `chat_thread_*` — every device × locale × theme byte-identical light↔dark
- `home_buyer_*` — same fingerprint
- `seller_home_*`, `own_profile_*`, `transaction_detail_*`,
  `listing_detail_*`, `listing_creation_*`, `category_browse_*`,
  `shipping_qr_*` — all show ~13–49 KB clusters of byte-identical pairs
- **100 distinct `{screen}_{locale}_{device}` keys** failing the gate

The fingerprint is "size identical, bytes identical, sizes cluster around
a small set of values per device class" — exactly what a single canonical
loading frame produces.

## Why this PR is diagnostic-only

Three production-hardening attempts were made and reverted (see `git
log` for the relevant branches):

1. **`runAsync` pump sequence (#211 round 1).** Replaced the fixed
   `pump(600ms)` with `pump → runAsync(600ms) → pump → pumpAndSettle`.
   CI ran the gate after the regen step and reported the same **100
   identical pairs** — the pump fix did not change the captured bytes.
2. **`sqflite_common_ffi` + `path_provider` channel mock (#211 round
   2).** Three layers of native-plugin shimming added a 3 MB native dep
   without unblocking any failing pair. `databaseFactoryFfiNoIsolate`
   workaround for `flutter_cache_manager` introduced more surface than
   it fixed.
3. **Two-phase `runAsync(200ms) + pump(600ms) + pump(100ms)` drain
   (#216).** Same outcome as attempt 1 — CI's `Regenerate & Diff
   Screenshots` job reported **100 identical pairs** unchanged. The
   pump rewrite produced zero byte differences in the captured PNGs.

## Updated root-cause hypothesis (post-#216)

Pixel-level inspection of the 240 PNGs currently committed on `dev`
shows the failure mode is **not** a pre-paint solid-color frame — it
is a **fully transparent canvas**. Every pixel of every "broken" PNG
is `(0, 0, 0, 0)` (RGBA zero), meaning the widget tree never painted
to the snapshot surface at all.

Bucketed by theme × device:

| Bucket | content | transparent |
|:------|:--------|:------------|
| `light/ios_67` | **20** | 0 |
| `light/desktop_1400` | **10** | 0 |
| every other `(theme, device)` | 0 | 220 |

So 30/240 PNGs (12.5%) render content. The 30 that paint share two
properties:

- They are the **first iteration** of their driver's
  `for (device) → for (locale) → for (theme)` loop. `ios_67` is the
  first entry in `kScreenshotDevices`; `desktop_1400` is the only
  entry in `kScreenshotDesktopDevices`.
- They are **light theme**.

Subsequent iterations within the same driver (different device, or
dark theme on the same device) consistently produce empty canvases
even though the driver does:

```dart
await tester.binding.setSurfaceSize(device.logicalSize);
addTearDown(() => tester.binding.setSurfaceSize(null));
```

This points at a **test-isolation defect** between `testWidgets`
iterations sharing the same binding, not an async-build draining
problem. Hypotheses worth testing:

1. `setSurfaceSize` does not actually take effect for the second+
   iteration without an additional `tester.pump()` cycle before
   `pumpWidget`.
2. The `goldenFileComparator` singleton (set in `setUpAll` to
   `TolerantGoldenFileComparator.forTestFile(…)`) caches the first
   surface and emits transparent for non-matching dimensions.
3. The `RasterCache` retains the previous test's loading-frame layer
   and serves a transparent texture when the next test rebuilds at a
   different surface size.
4. Riverpod's global `ProviderContainer` retains state from the prior
   test run; the second `pumpWidget` builds on a disposed container.
5. `EasyLocalization`'s asset cache is request-once; subsequent tests
   await a never-firing locale future.

A useful diagnostic before another fix attempt: dump
`tester.binding.renderView.previousLayer` and `find.byType(MaterialApp)
.evaluate().single.renderObject` after each pump phase, in the
**second** iteration of the canary, to confirm which phase swaps in
(or fails to swap in) the loaded layer.

Mahmut's review on PR #211
([Round 1](https://github.com/deelmarkt-org/app/pull/211#pullrequestreview-2473),
[Round 2](https://github.com/deelmarkt-org/app/pull/211#pullrequestreview-2475))
called this out: "step back rather than push another pump-tweak." This
PR scope-down does exactly that. It ships the tooling that makes the
problem visible, leaves a RED canary baseline for the eventual fix, and
documents the failure mode so the next attempt has clear acceptance
criteria.

## What this PR ships

| Surface | Change |
|:--------|:-------|
| `scripts/check_quality.dart` | New `--check-goldens` mode. Groups PNGs by `{screen}_{locale}_{device}`, reports each pair where light/dark are byte-identical. Standalone exit code: 0 = clean, 1 = violations. |
| `test/screenshots/drivers/chat_thread_screenshot_test.dart` | Adds an `'async provider resolution'` canary that calls `captureScreenshot` and asserts `tester.allWidgets.length > 50`. `skip`-marked today; flips GREEN once #203 ships a working pump fix. |
| `.github/workflows/screenshots.yml` | Runs `--check-goldens` after `--update-goldens` as a **warn-only** step (`continue-on-error: true`) so the inventory shows up in the run log without blocking the PR. |
| `test/screenshots/README.md` | Documents the issue + the local diagnostic command. Adds the `desktop_1400` row introduced in #193. |

No production code change. No new dependencies.

## Acceptance criteria for the eventual fix PR

The follow-up that closes #203 must:

1. Make `--check-goldens` pass GREEN on CI (zero identical pairs after
   regen) **and** verify via pixel inspection that all 240 PNGs are
   non-transparent (`alpha != 0` somewhere on each canvas).
2. Remove the `skip:` from the chat_thread canary; the canary must pass.
   The canary now asserts `find.byType(MessageBubble)
   .findsAtLeastNWidgets(1)` — a sharper signal than the original
   widget-count > 50 (skeleton trees can satisfy that).
3. Demonstrate test-isolation correctness: capture the second iteration
   of the canary (e.g. `ios_65 + dark`) and assert the same widget
   presence + non-transparent pixel sample.
4. Not introduce native-only dependencies (`sqflite_common_ffi`,
   `path_provider` mocks). The fix lives in driver setup/teardown,
   pump sequence, or how `captureScreenshot` builds its widget tree.
5. Re-enable `ScreenshotTheme.values` (instead of `[ScreenshotTheme.light]`)
   in the desktop drivers introduced in #193:
   - `home_buyer_desktop_screenshot_test.dart`
   - `favourites_desktop_screenshot_test.dart`
   - `category_detail_desktop_screenshot_test.dart`
   - `category_browse_desktop_screenshot_test.dart`
   - `messages_shell_desktop_screenshot_test.dart`
6. Auto-commit step in `screenshots.yml` should run **after**
   `--check-goldens` passes; otherwise a failing gate auto-pushes
   broken baselines back to the PR branch (regression seen in #216).

Until then, the desktop drivers stay light-only and the dark-mode
visual regression surface for those screens remains uncovered.

## Out of scope

- Actual capture-pipeline fix.
- Re-enabling dark variants in `#193` desktop drivers.
- Refactoring `screenshot_driver.dart` pump sequence.
- Any changes to `pubspec.yaml` / `pubspec.lock`.
- `seller_home_screenshot_test.dart` mode hack — that surface needs its
  own ticket.
