/// Screenshot driver — Listing creation screen.
///
/// Hero screen #3: seller value proposition — photo-first creation flow.
/// Spec: docs/screens/03-listings/02-listing-creation.md
/// Reference: PLAN-p43-aso.md §WS-B
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/sell/presentation/screens/listing_creation_screen.dart';

import '../_support/device_frames.dart';
import '../_support/screenshot_driver.dart';
import '../_support/seed_data.dart';

void main() {
  setUpAll(initScreenshotEnvironment);

  for (final device in kScreenshotDevices) {
    for (final locale in kScreenshotLocales) {
      for (final theme in ScreenshotTheme.values) {
        testWidgets('listing_creation ${device.id} $locale ${theme.name}', (
          tester,
        ) async {
          await captureScreenshot(
            tester: tester,
            screen: const ListingCreationScreen(),
            locale: locale,
            theme: theme,
            device: device,
            goldenName: 'listing_creation',
          );
        });
      }
    }
  }
}
