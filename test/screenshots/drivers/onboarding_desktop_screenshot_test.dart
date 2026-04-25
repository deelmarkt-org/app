/// Screenshot driver — Onboarding screen on desktop.
///
/// Captures the DESKTOP layout introduced in issue #196: a centred elevated
/// [Card] (max-width 720px) wrapping the 3-page [PageView].
/// Matches `docs/screens/01-auth/designs/onboarding_tablet_optimized_card`.
///
/// Mobile coverage: `onboarding_screen_test.dart` (widget tests) and the
/// onboarding screenshot test (to be added separately) cover compact layout.
///
/// ### Scope — light theme only, for now
///
/// Dark-theme async-built screens trip the pre-existing `captureScreenshot`
/// pre-paint-frame bug (see #203). Reintroduce
/// `for (final theme in ScreenshotTheme.values)` once #203 lands.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/onboarding/presentation/onboarding_screen.dart';

import '../_support/device_frames.dart';
import '../_support/screenshot_driver.dart';
import '../_support/seed_data.dart';

void main() {
  setUpAll(initScreenshotEnvironment);

  // Dark-theme goldens deliberately omitted per #203 — see library docstring.
  for (final device in kScreenshotDesktopDevices) {
    for (final locale in kScreenshotLocales) {
      testWidgets('onboarding_desktop ${device.id} $locale light', (
        tester,
      ) async {
        await captureScreenshot(
          tester: tester,
          screen: const OnboardingScreen(),
          locale: locale,
          theme: ScreenshotTheme.light,
          device: device,
          goldenName: 'onboarding_desktop',
        );
      });
    }
  }
}
