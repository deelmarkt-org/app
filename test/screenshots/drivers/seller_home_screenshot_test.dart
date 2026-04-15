/// Screenshot driver — Home screen (seller mode).
///
/// Hero screen #10: seller-mode home showing earning potential.
/// Spec: docs/screens/02-home/02-home-seller.md
/// Reference: PLAN-p43-aso.md §WS-B
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/domain/entities/home_mode.dart';
import 'package:deelmarkt/features/home/presentation/home_mode_notifier.dart';
import 'package:deelmarkt/features/home/presentation/home_screen.dart';

import '../_support/device_frames.dart';
import '../_support/screenshot_driver.dart';
import '../_support/seed_data.dart';

// Forces seller mode without needing a real Supabase User.
class _SellerModeNotifier extends HomeModeNotifier {
  @override
  HomeMode build() => HomeMode.seller;
}

void main() {
  setUpAll(initScreenshotEnvironment);

  for (final device in kScreenshotDevices) {
    for (final locale in kScreenshotLocales) {
      for (final theme in ScreenshotTheme.values) {
        testWidgets('seller_home ${device.id} $locale ${theme.name}', (
          tester,
        ) async {
          await captureScreenshot(
            tester: tester,
            screen: const HomeScreen(),
            locale: locale,
            theme: theme,
            device: device,
            goldenName: 'seller_home',
            extraOverrides: [
              homeModeNotifierProvider.overrideWith(_SellerModeNotifier.new),
            ],
          );
        });
      }
    }
  }
}
