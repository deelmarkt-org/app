/// Screenshot pipeline smoke test — P-43 ASO.
///
/// This file verifies that the screenshot infrastructure compiles and the
/// support libraries have no analysis errors. It does NOT generate PNGs itself.
///
/// To generate all 240 App Store / Play Console screenshots, run the drivers
/// directory directly:
///
///   flutter test --update-goldens test/screenshots/drivers/
///
/// To verify existing goldens match (CI mode):
///
///   flutter test test/screenshots/drivers/
///
/// Individual drivers (each generates 24 PNGs: 6 devices × 2 locales × 2 themes):
///   test/screenshots/drivers/home_buyer_screenshot_test.dart
///   test/screenshots/drivers/seller_home_screenshot_test.dart
///   test/screenshots/drivers/listing_detail_screenshot_test.dart
///   test/screenshots/drivers/listing_creation_screenshot_test.dart
///   test/screenshots/drivers/category_browse_screenshot_test.dart
///   test/screenshots/drivers/search_screenshot_test.dart
///   test/screenshots/drivers/chat_thread_screenshot_test.dart
///   test/screenshots/drivers/transaction_detail_screenshot_test.dart
///   test/screenshots/drivers/shipping_qr_screenshot_test.dart
///   test/screenshots/drivers/own_profile_screenshot_test.dart
///
/// Reference: PLAN-p43-aso.md §WS-A / §WS-B
library;

import 'package:flutter_test/flutter_test.dart';

import 'screenshots/_support/device_frames.dart';
import 'screenshots/_support/seed_data.dart';
import 'screenshots/_support/screenshot_driver.dart';

void main() {
  group('Screenshot infrastructure smoke test', () {
    test('device frame matrix has exactly 6 entries', () {
      expect(kScreenshotDevices, hasLength(6));
    });

    test('locales list has NL + EN', () {
      expect(kScreenshotLocales, containsAll(['nl_NL', 'en_US']));
    });

    test('theme enum has light + dark', () {
      expect(ScreenshotTheme.values, hasLength(2));
    });

    test('seed now is a fixed timestamp', () {
      expect(kScreenshotNow, equals(DateTime(2026, 4, 15, 14)));
    });

    test('total screenshot matrix size is 240', () {
      const screens = 10;
      final variants =
          kScreenshotDevices.length *
          kScreenshotLocales.length *
          ScreenshotTheme.values.length;
      expect(screens * variants, 240);
    });

    testWidgets('initScreenshotEnvironment completes without error', (
      tester,
    ) async {
      await initScreenshotEnvironment();
      // No assertions needed — failure is a thrown exception.
    });
  });
}
