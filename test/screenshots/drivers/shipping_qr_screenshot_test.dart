/// Screenshot driver — Shipping QR screen.
///
/// Hero screen #8: unique vs. competitors — QR label handoff.
/// Spec: docs/screens/05-shipping/01-shipping-qr.md
/// Reference: PLAN-p43-aso.md §WS-B
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/shipping/domain/entities/shipping_label.dart';
import 'package:deelmarkt/features/shipping/presentation/screens/shipping_qr_screen.dart';

import '../_support/device_frames.dart';
import '../_support/screenshot_driver.dart';
import '../_support/seed_data.dart';

final _mockLabel = ShippingLabel(
  id: kScreenshotShipmentId,
  transactionId: kScreenshotTransactionId,
  qrData: 'POSTNL-3S123456789NL',
  trackingNumber: '3S123456789NL',
  carrier: ShippingCarrier.postnl,
  destinationPostalCode: '1000 AB',
  createdAt: DateTime(2026, 4, 14, 11),
  shipByDeadline: DateTime(2026, 4, 17),
);

void main() {
  setUpAll(initScreenshotEnvironment);

  for (final device in kScreenshotDevices) {
    for (final locale in kScreenshotLocales) {
      for (final theme in ScreenshotTheme.values) {
        testWidgets('shipping_qr ${device.id} $locale ${theme.name}', (
          tester,
        ) async {
          await captureScreenshot(
            tester: tester,
            screen: ShippingQrScreen(label: _mockLabel),
            locale: locale,
            theme: theme,
            device: device,
            goldenName: 'shipping_qr',
          );
        });
      }
    }
  }
}
