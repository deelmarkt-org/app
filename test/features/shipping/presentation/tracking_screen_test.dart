import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/shipping/domain/entities/shipping_label.dart';
import 'package:deelmarkt/features/shipping/domain/entities/tracking_event.dart';
import 'package:deelmarkt/features/shipping/presentation/screens/tracking_screen.dart';
import 'package:deelmarkt/features/shipping/presentation/widgets/tracking_timeline.dart';

import '../../../../test/helpers/pump_app.dart';

ShippingLabel _label() => ShippingLabel(
  id: 'ship_001',
  transactionId: 'txn_001',
  qrData: 'https://postnl.nl/qr/3SDEVC1234567',
  trackingNumber: '3SDEVC1234567',
  carrier: ShippingCarrier.postnl,
  shipByDeadline: DateTime(2026, 3, 25, 18, 0),
  createdAt: DateTime(2026, 3, 23),
);

List<TrackingEvent> _events() => [
  TrackingEvent(
    id: 'evt_2',
    status: TrackingStatus.pickedUp,
    description: 'Picked up by carrier',
    timestamp: DateTime(2026, 3, 24, 10, 0),
    location: 'PostNL ServicePoint',
  ),
  TrackingEvent(
    id: 'evt_1',
    status: TrackingStatus.labelCreated,
    description: 'Label created',
    timestamp: DateTime(2026, 3, 23, 18, 0),
  ),
];

void main() {
  group('TrackingScreen', () {
    testWidgets('renders tracking timeline with events', (tester) async {
      await pumpTestScreen(
        tester,
        TrackingScreen(label: _label(), events: _events()),
      );

      expect(find.byType(TrackingTimeline), findsOneWidget);
      expect(find.text('Picked up by carrier'), findsOneWidget);
    });

    testWidgets('shows tracking number', (tester) async {
      await pumpTestScreen(
        tester,
        TrackingScreen(label: _label(), events: _events()),
      );

      expect(find.text('3SDEVC1234567'), findsOneWidget);
    });

    testWidgets('shows carrier name', (tester) async {
      await pumpTestScreen(
        tester,
        TrackingScreen(label: _label(), events: _events()),
      );

      expect(find.textContaining('shipping.carrierPostnl'), findsWidgets);
    });

    testWidgets('shows empty state when no events', (tester) async {
      await pumpTestScreen(
        tester,
        TrackingScreen(label: _label(), events: const []),
      );

      expect(find.textContaining('tracking.noUpdates'), findsWidgets);
      expect(find.byType(TrackingTimeline), findsNothing);
    });

    testWidgets('has app bar', (tester) async {
      await pumpTestScreen(
        tester,
        TrackingScreen(label: _label(), events: _events()),
      );

      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
