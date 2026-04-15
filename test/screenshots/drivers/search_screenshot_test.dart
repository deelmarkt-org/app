/// Screenshot driver — Search screen.
///
/// Hero screen #5: discovery power.
/// Spec: docs/screens/02-home/03-search.md
/// Reference: PLAN-p43-aso.md §WS-B
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/search/presentation/search_screen.dart';

import '../_support/device_frames.dart';
import '../_support/screenshot_driver.dart';
import '../_support/seed_data.dart';

void main() {
  setUpAll(initScreenshotEnvironment);

  for (final device in kScreenshotDevices) {
    for (final locale in kScreenshotLocales) {
      for (final theme in ScreenshotTheme.values) {
        testWidgets('search ${device.id} $locale ${theme.name}', (
          tester,
        ) async {
          await captureScreenshot(
            tester: tester,
            screen: const SearchScreen(),
            locale: locale,
            theme: theme,
            device: device,
            goldenName: 'search',
          );
        });
      }
    }
  }
}
