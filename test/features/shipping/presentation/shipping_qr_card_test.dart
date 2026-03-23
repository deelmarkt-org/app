import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:deelmarkt/features/shipping/domain/entities/shipping_label.dart';
import 'package:deelmarkt/features/shipping/presentation/widgets/shipping_qr_card.dart';

import '../../../../test/helpers/pump_app.dart';

ShippingLabel _label({
  ShippingCarrier carrier = ShippingCarrier.postnl,
  String qrData = 'https://postnl.nl/qr/3SDEVC1234567',
}) {
  return ShippingLabel(
    id: 'ship_001',
    transactionId: 'txn_001',
    qrData: qrData,
    trackingNumber: '3SDEVC1234567',
    carrier: carrier,
    shipByDeadline: DateTime(2026, 3, 25, 18, 0),
    createdAt: DateTime(2026, 3, 23),
  );
}

void main() {
  group('ShippingQrCard', () {
    testWidgets('renders QR code image', (tester) async {
      await pumpTestWidget(tester, ShippingQrCard(label: _label()));

      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('displays tracking number', (tester) async {
      await pumpTestWidget(tester, ShippingQrCard(label: _label()));

      expect(find.text('3SDEVC1234567'), findsOneWidget);
    });

    testWidgets('displays PostNL carrier badge', (tester) async {
      await pumpTestWidget(tester, ShippingQrCard(label: _label()));

      expect(find.text('PostNL'), findsOneWidget);
    });

    testWidgets('displays DHL carrier badge', (tester) async {
      await pumpTestWidget(
        tester,
        ShippingQrCard(label: _label(carrier: ShippingCarrier.dhl)),
      );

      expect(find.text('DHL'), findsOneWidget);
    });

    testWidgets('displays ship-by deadline', (tester) async {
      await pumpTestWidget(tester, ShippingQrCard(label: _label()));

      // The deadline text is inside the l10n key with formatted date arg
      // In tests without EasyLocalization, .tr(args:) returns the key path
      expect(find.textContaining('shipping.shipByDeadline'), findsWidgets);
    });

    testWidgets('has Semantics wrapper', (tester) async {
      await pumpTestWidget(tester, ShippingQrCard(label: _label()));

      final semantics = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label != null &&
            w.properties.label!.contains('PostNL'),
      );
      expect(semantics, findsWidgets);
    });
  });
}
