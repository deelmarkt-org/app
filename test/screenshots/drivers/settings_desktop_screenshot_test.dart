/// Screenshot driver — Settings screen on desktop.
///
/// Captures the DESKTOP layout introduced in issue #196: single-column
/// content capped at 720px (up from 600px default), centred on wide
/// viewports. Matches `docs/screens/07-profile/designs/settings_desktop_light`.
///
/// Mobile coverage: `settings_screen_test.dart` (widget tests) cover the
/// compact layout.
///
/// ### Scope — light theme only, for now
///
/// Dark-theme async-built screens trip the pre-existing `captureScreenshot`
/// pre-paint-frame bug (see #203). Reintroduce
/// `for (final theme in ScreenshotTheme.values)` once #203 lands.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/presentation/screens/settings_screen.dart';

import '../_support/device_frames.dart';
import '../_support/screenshot_driver.dart';
import '../_support/seed_data.dart';

void main() {
  setUpAll(initScreenshotEnvironment);

  // SettingsScreen uses settingsNotifierProvider + profileNotifierProvider.
  // useMockDataProvider=true (set in captureScreenshot) wires MockUserRepository
  // for profile data. settingsNotifier uses the same mock layer.
  //
  // Dark-theme goldens deliberately omitted per #203 — see library docstring.
  for (final device in kScreenshotDesktopDevices) {
    for (final locale in kScreenshotLocales) {
      testWidgets('settings_desktop ${device.id} $locale light', (
        tester,
      ) async {
        await captureScreenshot(
          tester: tester,
          screen: const SettingsScreen(),
          locale: locale,
          theme: ScreenshotTheme.light,
          device: device,
          goldenName: 'settings_desktop',
        );
      });
    }
  }
}
