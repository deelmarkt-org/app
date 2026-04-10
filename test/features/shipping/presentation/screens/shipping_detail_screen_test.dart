import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/shipping/domain/entities/shipping_label.dart';
import 'package:deelmarkt/features/shipping/domain/entities/tracking_event.dart';
import 'package:deelmarkt/features/shipping/presentation/screens/shipping_detail_screen.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';
import 'package:deelmarkt/widgets/trust/trust_banner.dart';

import '../../../../helpers/pump_app.dart';

ShippingLabel _label() => ShippingLabel(
  id: 'ship-001',
  transactionId: 'txn-001',
  qrData: '3SDEVC1234567|POSTNL|1012RR',
  trackingNumber: '3SDEVC1234567',
  carrier: ShippingCarrier.postnl,
  destinationPostalCode: '1012RR',
  shipByDeadline: DateTime(2026, 4, 12),
  createdAt: DateTime(2026, 4, 8),
);

void main() {
  group('ShippingDetailScreen', () {
    testWidgets('renders trust banner', (tester) async {
      await pumpTestScreen(
        tester,
        ShippingDetailScreen(label: _label(), events: const []),
      );

      expect(find.byType(TrustBanner), findsOneWidget);
    });

    testWidgets('renders carrier card with tracking number', (tester) async {
      await pumpTestScreen(
        tester,
        ShippingDetailScreen(label: _label(), events: const []),
      );

      expect(find.text('3SDEVC1234567'), findsOneWidget);
    });

    testWidgets('renders three action buttons', (tester) async {
      await pumpTestScreen(
        tester,
        ShippingDetailScreen(label: _label(), events: const []),
      );

      expect(find.byType(DeelButton), findsNWidgets(3));
    });

    testWidgets('shows no updates text when events empty', (tester) async {
      await pumpTestScreen(
        tester,
        ShippingDetailScreen(label: _label(), events: const []),
      );

      expect(find.textContaining('tracking.noUpdates'), findsOneWidget);
    });

    testWidgets('shows latest event description when events present', (
      tester,
    ) async {
      final events = [
        TrackingEvent(
          id: 'evt-001',
          status: TrackingStatus.inTransit,
          description: 'In sorteercentrum',
          timestamp: DateTime(2026, 4, 9, 14),
        ),
      ];

      await pumpTestScreen(
        tester,
        ShippingDetailScreen(label: _label(), events: events),
      );

      expect(find.text('In sorteercentrum'), findsOneWidget);
    });

    testWidgets('wraps content in ResponsiveBody', (tester) async {
      await pumpTestScreen(
        tester,
        ShippingDetailScreen(label: _label(), events: const []),
      );

      expect(find.byType(ResponsiveBody), findsOneWidget);
    });

    testWidgets('has Semantics labels', (tester) async {
      await pumpTestScreen(
        tester,
        ShippingDetailScreen(label: _label(), events: const []),
      );

      expect(find.byType(Semantics), findsWidgets);
    });
  });
}
