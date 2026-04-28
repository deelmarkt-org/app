/// Screenshot driver — Own profile screen on desktop.
///
/// Captures the DESKTOP layout introduced in issue #196: content capped
/// at 900px (up from the previous 600px default) with an adaptive
/// listings grid (2→3→4 columns via [AdaptiveListingGrid]).
/// Matches `docs/screens/07-profile/designs/own_profile_desktop_light`.
///
/// Mobile coverage: `own_profile_screenshot_test.dart` covers compact layout.
///
/// ### Scope — light theme only, for now
///
/// Dark-theme async-built screens trip the pre-existing `captureScreenshot`
/// pre-paint-frame bug (see #203). Reintroduce
/// `for (final theme in ScreenshotTheme.values)` once #203 lands.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/presentation/screens/own_profile_screen.dart';

import '../_support/device_frames.dart';
import '../_support/screenshot_driver.dart';
import '../_support/seed_data.dart';

void main() {
  setUpAll(initScreenshotEnvironment);

  // OwnProfileScreen loads user data from userRepositoryProvider.
  // useMockDataProvider=true (set in captureScreenshot) injects
  // MockUserRepository, which returns mock user-001 — no extra overrides.
  //
  // Dark-theme goldens deliberately omitted per #203 — see library docstring.
  for (final device in kScreenshotDesktopDevices) {
    for (final locale in kScreenshotLocales) {
      testWidgets('own_profile_desktop ${device.id} $locale light', (
        tester,
      ) async {
        await captureScreenshot(
          tester: tester,
          screen: const OwnProfileScreen(),
          locale: locale,
          theme: ScreenshotTheme.light,
          device: device,
          goldenName: 'own_profile_desktop',
        );
      });
    }
  }
}
