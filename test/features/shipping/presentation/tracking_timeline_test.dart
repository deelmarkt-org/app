import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/shipping/domain/entities/tracking_event.dart';
import 'package:deelmarkt/features/shipping/presentation/widgets/tracking_timeline.dart';

import '../../../../test/helpers/pump_app.dart';

List<TrackingEvent> _events() => [
  TrackingEvent(
    id: 'evt_3',
    status: TrackingStatus.inTransit,
    description: 'In transit',
    timestamp: DateTime(2026, 3, 24, 14, 30),
    location: 'Amsterdam Sorting Centre',
  ),
  TrackingEvent(
    id: 'evt_2',
    status: TrackingStatus.pickedUp,
    description: 'Picked up by carrier',
    timestamp: DateTime(2026, 3, 24, 10),
    location: 'PostNL ServicePoint Centrum',
  ),
  TrackingEvent(
    id: 'evt_1',
    status: TrackingStatus.labelCreated,
    description: 'Label created',
    timestamp: DateTime(2026, 3, 23, 18),
  ),
];

void main() {
  group('TrackingTimeline', () {
    testWidgets('renders all events', (tester) async {
      await pumpTestWidget(tester, TrackingTimeline(events: _events()));

      expect(find.text('In transit'), findsOneWidget);
      expect(find.text('Picked up by carrier'), findsOneWidget);
      expect(find.text('Label created'), findsOneWidget);
    });

    testWidgets('displays locations when present', (tester) async {
      await pumpTestWidget(tester, TrackingTimeline(events: _events()));

      expect(find.text('Amsterdam Sorting Centre'), findsOneWidget);
      expect(find.text('PostNL ServicePoint Centrum'), findsOneWidget);
    });

    testWidgets('renders nothing for empty events', (tester) async {
      await pumpTestWidget(tester, const TrackingTimeline(events: []));

      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('first event is visually active', (tester) async {
      await pumpTestWidget(tester, TrackingTimeline(events: _events()));

      // First event text should be bold (w600)
      final firstText = tester.widget<Text>(find.text('In transit'));
      expect(firstText.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('has Semantics on each event', (tester) async {
      await pumpTestWidget(tester, TrackingTimeline(events: _events()));

      final semantics = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label != null &&
            w.properties.label!.contains('In transit'),
      );
      expect(semantics, findsOneWidget);
    });

    testWidgets('displays timestamps', (tester) async {
      await pumpTestWidget(tester, TrackingTimeline(events: _events()));

      // Formatters.shortDateTime with default 'en' locale in test env
      expect(find.textContaining('2026'), findsWidgets);
      expect(find.textContaining('14:30'), findsOneWidget);
      expect(find.textContaining('10:00'), findsOneWidget);
    });

    testWidgets('single delivered event renders correctly', (tester) async {
      await pumpTestWidget(
        tester,
        TrackingTimeline(
          events: [
            TrackingEvent(
              id: 'evt_d',
              status: TrackingStatus.delivered,
              description: 'Delivered',
              timestamp: DateTime(2026, 3, 25, 12),
              location: 'Front door',
            ),
          ],
        ),
      );

      expect(find.text('Delivered'), findsOneWidget);
      expect(find.text('Front door'), findsOneWidget);
    });
  });
}
