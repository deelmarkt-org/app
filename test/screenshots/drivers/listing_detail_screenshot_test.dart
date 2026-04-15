/// Screenshot driver — Listing detail screen.
///
/// Hero screen #2: price, photos, trust signals.
/// Spec: docs/screens/03-listings/01-listing-detail.md
/// Reference: PLAN-p43-aso.md §WS-B
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/listing_detail/presentation/listing_detail_screen.dart';

import '../_support/device_frames.dart';
import '../_support/screenshot_driver.dart';
import '../_support/seed_data.dart';

void main() {
  setUpAll(initScreenshotEnvironment);

  for (final device in kScreenshotDevices) {
    for (final locale in kScreenshotLocales) {
      for (final theme in ScreenshotTheme.values) {
        testWidgets('listing_detail ${device.id} $locale ${theme.name}', (
          tester,
        ) async {
          await captureScreenshot(
            tester: tester,
            screen: const ListingDetailScreen(
              listingId: kScreenshotFeaturedListingId,
            ),
            locale: locale,
            theme: theme,
            device: device,
            goldenName: 'listing_detail',
          );
        });
      }
    }
  }
}
