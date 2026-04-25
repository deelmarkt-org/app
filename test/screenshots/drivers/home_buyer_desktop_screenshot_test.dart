/// Screenshot driver — Home screen (buyer mode) on desktop.
///
/// Captures the DESKTOP layout introduced in #193 PR A: content capped at
/// [Breakpoints.large] (1200px) on ultra-wide viewports. Matches
/// `docs/screens/02-home/designs/home_desktop_light`.
///
/// Mobile coverage lives in `home_buyer_screenshot_test.dart` — unchanged.
///
/// ### Scope — light theme only, for now
///
/// Dark-theme async-built screens trip the pre-existing `captureScreenshot`
/// pre-paint-frame bug (see #203). Evidence: on `dev`,
/// `chat_thread_en_US_{light,dark}_android_phone` share blob `492a7ff0`
/// because the dark path captures before `HomeDataView` paints. Light path
/// is unaffected because shimmers and card colours on a light scaffold
/// produce varied bytes even with early capture.
///
/// Reintroduce `for (final theme in ScreenshotTheme.values)` once #203
/// lands the capture-infra fix.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/home/presentation/home_screen.dart';

import '../_support/device_frames.dart';
import '../_support/screenshot_driver.dart';
import '../_support/seed_data.dart';

void main() {
  setUpAll(initScreenshotEnvironment);

  // Dark-theme goldens deliberately omitted per #203 — see library docstring.
  for (final device in kScreenshotDesktopDevices) {
    for (final locale in kScreenshotLocales) {
      testWidgets('home_buyer_desktop ${device.id} $locale light', (
        tester,
      ) async {
        await captureScreenshot(
          tester: tester,
          screen: const HomeScreen(),
          locale: locale,
          theme: ScreenshotTheme.light,
          device: device,
          goldenName: 'home_buyer_desktop',
          extraOverrides: [currentUserProvider.overrideWithValue(null)],
        );
      });
    }
  }
}
