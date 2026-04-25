/// Screenshot driver — Favourites screen on desktop.
///
/// Captures the DESKTOP layout introduced in #193 PR A: content capped at
/// [Breakpoints.large] (1200px) on ultra-wide viewports. Matches
/// `docs/screens/03-listings/designs/favourites_desktop_expanded`.
///
/// Mobile coverage: `FavouritesScreen` widget tests in
/// `test/features/home/presentation/screens/favourites_screen_test.dart`
/// cover compact layout invariants; a mobile screenshot driver does not
/// yet exist because the screen ships 2-col by default and is covered
/// transitively by the widget tests.
///
/// ### Scope — light theme only, for now
///
/// Dark-theme async-built screens trip the pre-existing `captureScreenshot`
/// pre-paint-frame bug (see #203). Reintroduce
/// `for (final theme in ScreenshotTheme.values)` once #203 lands.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/presentation/screens/favourites_screen.dart';

import '../_support/device_frames.dart';
import '../_support/screenshot_driver.dart';
import '../_support/seed_data.dart';

void main() {
  setUpAll(initScreenshotEnvironment);

  // Dark-theme goldens deliberately omitted per #203 — see library docstring.
  for (final device in kScreenshotDesktopDevices) {
    for (final locale in kScreenshotLocales) {
      testWidgets('favourites_desktop ${device.id} $locale light', (
        tester,
      ) async {
        await captureScreenshot(
          tester: tester,
          screen: const FavouritesScreen(),
          locale: locale,
          theme: ScreenshotTheme.light,
          device: device,
          goldenName: 'favourites_desktop',
        );
      });
    }
  }
}
