import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:deelmarkt/features/shipping/domain/entities/shipping_label.dart';
import 'package:deelmarkt/features/shipping/presentation/screens/shipping_qr_screen.dart';
import 'package:deelmarkt/features/shipping/presentation/widgets/shipping_qr_card.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';
import 'package:deelmarkt/widgets/trust/trust_banner.dart';

import '../../../../helpers/pump_app.dart';

ShippingLabel _label() {
  return ShippingLabel(
    id: 'ship_001',
    transactionId: 'txn_001',
    qrData: 'https://postnl.nl/qr/3SDEVC1234567',
    trackingNumber: '3SDEVC1234567',
    carrier: ShippingCarrier.postnl,
    destinationPostalCode: '2521CA',
    shipByDeadline: DateTime(2026, 3, 25, 18),
    createdAt: DateTime(2026, 3, 23),
  );
}

void main() {
  group('ShippingQrScreen', () {
    testWidgets('renders QR card', (tester) async {
      await pumpTestScreen(tester, ShippingQrScreen(label: _label()));

      expect(find.byType(ShippingQrCard), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('renders escrow trust banner', (tester) async {
      await pumpTestScreen(tester, ShippingQrScreen(label: _label()));

      expect(find.byType(TrustBanner), findsOneWidget);
    });

    testWidgets('has app bar with title', (tester) async {
      await pumpTestScreen(tester, ShippingQrScreen(label: _label()));

      // Title uses l10n key which renders as key path in tests
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('has find service point button', (tester) async {
      await pumpTestScreen(tester, ShippingQrScreen(label: _label()));

      expect(find.textContaining('shipping.findServicePoint'), findsOneWidget);
    });

    testWidgets('find service point button is enabled and tappable', (
      tester,
    ) async {
      await pumpTestScreen(tester, ShippingQrScreen(label: _label()));

      // Button should be enabled (onPressed is not null — wired to navigation)
      final buttonFinder = find.byType(DeelButton);
      expect(buttonFinder, findsOneWidget);

      final button = tester.widget<DeelButton>(buttonFinder);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('has instruction card', (tester) async {
      await pumpTestScreen(tester, ShippingQrScreen(label: _label()));

      expect(find.textContaining('shipping.scanAtServicePoint'), findsWidgets);
    });

    testWidgets('renders correctly in dark mode', (tester) async {
      await pumpTestScreen(
        tester,
        ShippingQrScreen(label: _label()),
        theme: ThemeData.dark(),
      );

      expect(find.byType(ShippingQrCard), findsOneWidget);
      expect(find.textContaining('shipping.scanAtServicePoint'), findsWidgets);
    });
  });
}
