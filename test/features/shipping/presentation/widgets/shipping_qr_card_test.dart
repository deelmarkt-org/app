import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/shipping/domain/entities/shipping_label.dart';
import 'package:deelmarkt/features/shipping/presentation/widgets/shipping_qr_card.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('ShippingQrCard', () {
    final label = ShippingLabel(
      id: 'ship-001',
      transactionId: 'txn-001',
      qrData: '3SDEVC1234567|POSTNL|2521CA',
      trackingNumber: '3SDEVC1234567',
      carrier: ShippingCarrier.postnl,
      destinationPostalCode: '2521CA',
      shipByDeadline: DateTime(2026, 4, 12),
      createdAt: DateTime(2026, 4, 8),
    );

    testWidgets('renders QR code and tracking number', (tester) async {
      await pumpTestWidget(tester, ShippingQrCard(label: label));

      expect(find.text('3SDEVC1234567'), findsOneWidget);
    });

    testWidgets('shows deadline when shipByDeadline is set', (tester) async {
      await pumpTestWidget(tester, ShippingQrCard(label: label));

      expect(find.textContaining('shipping.shipByDeadline'), findsOneWidget);
    });

    testWidgets('hides deadline when shipByDeadline is null', (tester) async {
      final noDeadline = ShippingLabel(
        id: 'ship-002',
        transactionId: 'txn-002',
        qrData: 'JVGL0987654321|DHL|1015AA',
        trackingNumber: 'JVGL0987654321',
        carrier: ShippingCarrier.dhl,
        destinationPostalCode: '1015AA',
        createdAt: DateTime(2026, 4, 6),
      );

      await pumpTestWidget(tester, ShippingQrCard(label: noDeadline));

      expect(find.textContaining('shipping.shipByDeadline'), findsNothing);
    });

    testWidgets('has Semantics label', (tester) async {
      await pumpTestWidget(tester, ShippingQrCard(label: label));

      expect(find.byType(Semantics), findsWidgets);
    });
  });
}
