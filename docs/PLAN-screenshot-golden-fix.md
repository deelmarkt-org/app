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

Two production-hardening attempts were made on this branch and reverted
(see `git log` before `HEAD`):

1. **`runAsync` pump sequence.** Replaced the fixed `pump(600ms)` with
   `pump → runAsync(600ms) → pump → pumpAndSettle`. CI ran the gate after
   the regen step and reported the same **100 identical pairs** — the
   pump fix did not change the captured bytes.
2. **`sqflite_common_ffi` + `path_provider` channel mock.** Three layers
   of native-plugin shimming added a 3 MB native dep without unblocking
   any failing pair. `databaseFactoryFfiNoIsolate` workaround for
   `flutter_cache_manager` introduced more surface than it fixed.

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
   regen).
2. Remove the `skip:` from the chat_thread canary; the canary must pass.
3. Not introduce native-only dependencies (`sqflite_common_ffi`,
   `path_provider` mocks). The fix lives in the pump sequence or in how
   `captureScreenshot` builds its widget tree.
4. Re-enable `ScreenshotTheme.values` (instead of `[ScreenshotTheme.light]`)
   in the desktop drivers introduced in #193:
   - `home_buyer_desktop_screenshot_test.dart`
   - `favourites_desktop_screenshot_test.dart`
   - `category_detail_desktop_screenshot_test.dart`
   - `category_browse_desktop_screenshot_test.dart`
   - `messages_shell_desktop_screenshot_test.dart`

Until then, the desktop drivers stay light-only and the dark-mode
visual regression surface for those screens remains uncovered.

## Out of scope

- Actual capture-pipeline fix.
- Re-enabling dark variants in `#193` desktop drivers.
- Refactoring `screenshot_driver.dart` pump sequence.
- Any changes to `pubspec.yaml` / `pubspec.lock`.
- `seller_home_screenshot_test.dart` mode hack — that surface needs its
  own ticket.
