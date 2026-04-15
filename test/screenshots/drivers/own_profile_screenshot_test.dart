/// Screenshot driver — Own profile screen.
///
/// Hero screen #9: badges, verified trust, review score.
/// Spec: docs/screens/07-profile/01-own-profile.md
/// Reference: PLAN-p43-aso.md §WS-B
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/presentation/screens/own_profile_screen.dart';

import '../_support/device_frames.dart';
import '../_support/screenshot_driver.dart';
import '../_support/seed_data.dart';

void main() {
  setUpAll(initScreenshotEnvironment);

  // OwnProfileScreen loads user data from userRepositoryProvider.
  // useMockDataProvider=true (set in captureScreenshot) injects MockUserRepository,
  // which returns mock user-001 (Sophie Visser) — no additional overrides needed.
  for (final device in kScreenshotDevices) {
    for (final locale in kScreenshotLocales) {
      for (final theme in ScreenshotTheme.values) {
        testWidgets('own_profile ${device.id} $locale ${theme.name}', (
          tester,
        ) async {
          await captureScreenshot(
            tester: tester,
            screen: const OwnProfileScreen(),
            locale: locale,
            theme: theme,
            device: device,
            goldenName: 'own_profile',
          );
        });
      }
    }
  }
}
