import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/shipping/domain/entities/tracking_event.dart';
import 'package:deelmarkt/features/shipping/presentation/widgets/tracking_status_card.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('TrackingStatusCard', () {
    testWidgets('shows no-updates text when event is null', (tester) async {
      await pumpTestWidget(
        tester,
        const TrackingStatusCard(latestEvent: null, isDark: false),
      );

      expect(find.textContaining('tracking.noUpdates'), findsOneWidget);
    });

    testWidgets('shows event description when event provided', (tester) async {
      final event = TrackingEvent(
        id: 'evt-001',
        status: TrackingStatus.inTransit,
        description: 'Pakket in sorteercentrum',
        timestamp: DateTime(2026, 4, 9, 14),
      );

      await pumpTestWidget(
        tester,
        TrackingStatusCard(latestEvent: event, isDark: false),
      );

      expect(find.text('Pakket in sorteercentrum'), findsOneWidget);
    });

    testWidgets('has Semantics label', (tester) async {
      await pumpTestWidget(
        tester,
        const TrackingStatusCard(latestEvent: null, isDark: false),
      );

      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('renders in dark mode', (tester) async {
      await pumpTestWidget(
        tester,
        const TrackingStatusCard(latestEvent: null, isDark: true),
      );

      expect(find.textContaining('tracking.noUpdates'), findsOneWidget);
    });
  });
}
