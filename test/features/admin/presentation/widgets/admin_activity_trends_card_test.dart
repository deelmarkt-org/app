import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_activity_trends_card.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('AdminActivityTrendsCard', () {
    testWidgets('renders title key', (tester) async {
      await pumpTestWidget(tester, const AdminActivityTrendsCard());

      expect(find.text('admin.empty.trends_title'), findsOneWidget);
    });

    testWidgets('renders empty body key', (tester) async {
      await pumpTestWidget(tester, const AdminActivityTrendsCard());

      expect(find.text('admin.empty.trends_empty'), findsOneWidget);
    });

    testWidgets('lays out title above body in a Column with start cross-axis '
        'alignment', (tester) async {
      await pumpTestWidget(tester, const AdminActivityTrendsCard());

      // The widget renders a single Column inside its Container.
      final column = tester.widget<Column>(
        find.descendant(
          of: find.byType(AdminActivityTrendsCard),
          matching: find.byType(Column),
        ),
      );
      expect(column.crossAxisAlignment, CrossAxisAlignment.start);

      // Vertical order: title appears above body in the rendered tree.
      final titleY =
          tester.getTopLeft(find.text('admin.empty.trends_title')).dy;
      final bodyY = tester.getTopLeft(find.text('admin.empty.trends_empty')).dy;
      expect(titleY, lessThan(bodyY));
    });

    testWidgets('expands to full width via Container(width: infinity)', (
      tester,
    ) async {
      await pumpTestWidget(tester, const AdminActivityTrendsCard());

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AdminActivityTrendsCard),
          matching: find.byType(Container),
        ),
      );
      expect(container.constraints?.maxWidth, double.infinity);
    });

    testWidgets('uses DeelmarktRadius.xl rounded corners', (tester) async {
      await pumpTestWidget(tester, const AdminActivityTrendsCard());

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AdminActivityTrendsCard),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(
        decoration.borderRadius,
        BorderRadius.circular(DeelmarktRadius.xl),
      );
    });

    testWidgets('renders without exception in dark mode', (tester) async {
      await pumpTestWidget(
        tester,
        const AdminActivityTrendsCard(),
        theme: ThemeData.dark(),
      );

      expect(find.byType(AdminActivityTrendsCard), findsOneWidget);
      expect(find.text('admin.empty.trends_title'), findsOneWidget);
      expect(find.text('admin.empty.trends_empty'), findsOneWidget);
    });
  });
}
