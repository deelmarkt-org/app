import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/admin/presentation/widgets/admin_empty_hero_card.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('AdminEmptyHeroCard', () {
    testWidgets('renders title + subtitle + refresh CTA l10n keys', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        AdminEmptyHeroCard(onRefresh: () {}, onViewLogs: null),
      );

      expect(find.text('admin.empty.title'), findsOneWidget);
      expect(find.text('admin.empty.subtitle'), findsOneWidget);
      expect(find.text('admin.empty.refresh'), findsOneWidget);
    });

    testWidgets('hides view-logs link when onViewLogs is null', (tester) async {
      await pumpTestWidget(
        tester,
        AdminEmptyHeroCard(onRefresh: () {}, onViewLogs: null),
      );

      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('shows view-logs link when onViewLogs is provided', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        AdminEmptyHeroCard(onRefresh: () {}, onViewLogs: () {}),
      );

      expect(find.byType(TextButton), findsOneWidget);
      expect(find.text('admin.empty.view_logs'), findsOneWidget);
    });

    testWidgets('refresh button fires onRefresh callback', (tester) async {
      var refreshCalled = 0;
      await pumpTestWidget(
        tester,
        AdminEmptyHeroCard(onRefresh: () => refreshCalled++, onViewLogs: null),
      );

      await tester.tap(find.text('admin.empty.refresh'));
      await tester.pump();

      expect(refreshCalled, 1);
    });

    testWidgets('view-logs link fires onViewLogs callback', (tester) async {
      var viewLogsCalled = 0;
      await pumpTestWidget(
        tester,
        AdminEmptyHeroCard(
          onRefresh: () {},
          onViewLogs: () => viewLogsCalled++,
        ),
      );

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(viewLogsCalled, 1);
    });
  });
}
