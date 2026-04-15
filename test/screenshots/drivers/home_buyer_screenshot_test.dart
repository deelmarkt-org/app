/// Screenshot driver — Home screen (buyer mode).
///
/// Hero screen #1: first impression for browsing buyers.
/// Spec: docs/screens/02-home/01-home-buyer.md
/// Reference: PLAN-p43-aso.md §WS-B
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/home/presentation/home_screen.dart';

import '../_support/device_frames.dart';
import '../_support/screenshot_driver.dart';
import '../_support/seed_data.dart';

void main() {
  setUpAll(initScreenshotEnvironment);

  for (final device in kScreenshotDevices) {
    for (final locale in kScreenshotLocales) {
      for (final theme in ScreenshotTheme.values) {
        testWidgets('home_buyer ${device.id} $locale ${theme.name}', (
          tester,
        ) async {
          await captureScreenshot(
            tester: tester,
            screen: const HomeScreen(),
            locale: locale,
            theme: theme,
            device: device,
            goldenName: 'home_buyer',
            extraOverrides: [currentUserProvider.overrideWithValue(null)],
          );
        });
      }
    }
  }
}
