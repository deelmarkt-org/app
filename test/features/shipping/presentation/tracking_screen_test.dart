import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/theme.dart';
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
  shipByDeadline: DateTime(2026, 3, 25, 18),
  createdAt: DateTime(2026, 3, 23),
);

List<TrackingEvent> _events() => [
  TrackingEvent(
    id: 'evt_2',
    status: TrackingStatus.pickedUp,
    description: 'Picked up by carrier',
    timestamp: DateTime(2026, 3, 24, 10),
    location: 'PostNL ServicePoint',
  ),
  TrackingEvent(
    id: 'evt_1',
    status: TrackingStatus.labelCreated,
    description: 'Label created',
    timestamp: DateTime(2026, 3, 23, 18),
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

    testWidgets('renders correctly in dark mode', (tester) async {
      await pumpTestScreen(
        tester,
        TrackingScreen(label: _label(), events: _events()),
        theme: DeelmarktTheme.dark,
      );

      expect(find.byType(TrackingTimeline), findsOneWidget);
      expect(find.text('3SDEVC1234567'), findsOneWidget);
    });

    testWidgets('dark mode empty state renders correctly', (tester) async {
      await pumpTestScreen(
        tester,
        TrackingScreen(label: _label(), events: const []),
        theme: DeelmarktTheme.dark,
      );

      expect(find.textContaining('tracking.noUpdates'), findsWidgets);
      expect(find.byType(TrackingTimeline), findsNothing);
    });

    testWidgets('dark mode uses dark color tokens on carrier header', (
      tester,
    ) async {
      await pumpTestScreen(
        tester,
        TrackingScreen(label: _label(), events: _events()),
        theme: DeelmarktTheme.dark,
      );

      // Carrier icon should use dark secondary color
      final icon = tester.widget<Icon>(
        find.byIcon(PhosphorIcons.package(PhosphorIconsStyle.fill)),
      );
      expect(icon.color, DeelmarktColors.darkSecondary);
    });

    testWidgets('dark mode uses dark tokens on tracking number card', (
      tester,
    ) async {
      await pumpTestScreen(
        tester,
        TrackingScreen(label: _label(), events: _events()),
        theme: DeelmarktTheme.dark,
      );

      // Find the tracking number card container
      final containers = tester.widgetList<Container>(find.byType(Container));
      final cardContainer = containers.where((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color == DeelmarktColors.darkSurfaceElevated;
        }
        return false;
      });
      expect(cardContainer, isNotEmpty);
    });

    testWidgets('light mode uses light color tokens on carrier header', (
      tester,
    ) async {
      await pumpTestScreen(
        tester,
        TrackingScreen(label: _label(), events: _events()),
        theme: DeelmarktTheme.light,
      );

      final icon = tester.widget<Icon>(
        find.byIcon(PhosphorIcons.package(PhosphorIconsStyle.fill)),
      );
      expect(icon.color, DeelmarktColors.secondary);
    });

    testWidgets('DHL carrier renders correctly', (tester) async {
      final dhlLabel = ShippingLabel(
        id: 'ship_002',
        transactionId: 'txn_002',
        qrData: 'https://dhl.nl/qr/JJD000123456',
        trackingNumber: 'JJD000123456',
        carrier: ShippingCarrier.dhl,
        shipByDeadline: DateTime(2026, 3, 25, 18),
        createdAt: DateTime(2026, 3, 23),
      );

      await pumpTestScreen(
        tester,
        TrackingScreen(label: dhlLabel, events: _events()),
      );

      expect(find.textContaining('shipping.carrierDhl'), findsWidgets);
      expect(find.text('JJD000123456'), findsOneWidget);
    });
  });
}
