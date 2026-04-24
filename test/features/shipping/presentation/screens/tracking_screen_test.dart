import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/shipping/domain/entities/shipping_label.dart';
import 'package:deelmarkt/features/shipping/domain/entities/tracking_event.dart';
import 'package:deelmarkt/features/shipping/presentation/screens/tracking_screen.dart';
import 'package:deelmarkt/features/shipping/presentation/widgets/tracking_timeline.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';

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

TrackingEvent _event() => TrackingEvent(
  id: 'evt-1',
  status: TrackingStatus.inTransit,
  description: 'In transit',
  location: 'Amsterdam',
  timestamp: DateTime(2026, 4, 9, 10),
);

void main() {
  group('TrackingScreen', () {
    testWidgets('renders timeline when events present', (tester) async {
      await pumpTestScreen(
        tester,
        TrackingScreen(label: _label(), events: [_event()]),
      );
      expect(find.byType(TrackingTimeline), findsOneWidget);
    });

    testWidgets('renders empty state when no events', (tester) async {
      await pumpTestScreen(
        tester,
        TrackingScreen(label: _label(), events: const []),
      );
      expect(find.byType(TrackingTimeline), findsNothing);
      expect(find.textContaining('tracking.noUpdates'), findsOneWidget);
    });

    testWidgets('caps content at 800px on expanded viewport — see #206', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpTestScreen(
        tester,
        TrackingScreen(label: _label(), events: [_event()]),
      );

      final body = tester.widget<ResponsiveBody>(
        find.descendant(
          of: find.byType(TrackingScreen),
          matching: find.byType(ResponsiveBody),
        ),
      );
      expect(body.maxWidth, 800);
    });
  });
}
