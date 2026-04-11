import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/admin/presentation/widgets/admin_stat_card.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('AdminStatCard', () {
    testWidgets('renders count as text', (tester) async {
      await pumpTestWidget(
        tester,
        const AdminStatCard(
          icon: Icons.flag,
          count: 12,
          label: 'Flagged items',
        ),
      );

      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('renders label text', (tester) async {
      await pumpTestWidget(
        tester,
        const AdminStatCard(icon: Icons.flag, count: 5, label: 'Open disputes'),
      );

      expect(find.text('Open disputes'), findsOneWidget);
    });

    testWidgets('renders countText instead of count when provided', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const AdminStatCard(
          icon: Icons.euro,
          count: 12450,
          countText: '\u20AC12.450',
          label: 'Revenue',
        ),
      );

      expect(find.text('\u20AC12.450'), findsOneWidget);
      expect(find.text('12450'), findsNothing);
    });

    testWidgets('renders badgeText when provided', (tester) async {
      await pumpTestWidget(
        tester,
        const AdminStatCard(
          icon: Icons.flag,
          count: 7,
          label: 'Flagged',
          badgeText: '+2 vandaag',
        ),
      );

      expect(find.text('+2 vandaag'), findsOneWidget);
    });

    testWidgets('has Semantics label with count', (tester) async {
      await pumpTestWidget(
        tester,
        const AdminStatCard(icon: Icons.flag, count: 9, label: 'Reports'),
      );

      final semantics = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == 'Reports: 9',
        ),
      );
      expect(semantics, isNotNull);
    });

    testWidgets('has Semantics label with countText when provided', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const AdminStatCard(
          icon: Icons.euro,
          count: 500,
          countText: '\u20AC500',
          label: 'Revenue',
        ),
      );

      final semantics = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Revenue: \u20AC500',
        ),
      );
      expect(semantics, isNotNull);
    });
  });
}
