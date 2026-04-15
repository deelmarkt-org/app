/// Screenshot driver — Category browse screen.
///
/// Hero screen #4: depth of inventory / discovery.
/// Spec: docs/screens/02-home/04-category-browse.md
/// Reference: PLAN-p43-aso.md §WS-B
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/presentation/screens/category_browse_screen.dart';

import '../_support/device_frames.dart';
import '../_support/screenshot_driver.dart';
import '../_support/seed_data.dart';

void main() {
  setUpAll(initScreenshotEnvironment);

  for (final device in kScreenshotDevices) {
    for (final locale in kScreenshotLocales) {
      for (final theme in ScreenshotTheme.values) {
        testWidgets('category_browse ${device.id} $locale ${theme.name}', (
          tester,
        ) async {
          await captureScreenshot(
            tester: tester,
            screen: const CategoryBrowseScreen(),
            locale: locale,
            theme: theme,
            device: device,
            goldenName: 'category_browse',
          );
        });
      }
    }
  }
}
