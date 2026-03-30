import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/onboarding/presentation/widgets/page_dot_indicator.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('PageDotIndicator', () {
    testWidgets('renders correct number of dots', (tester) async {
      await pumpTestWidget(
        tester,
        const PageDotIndicator(currentPage: 0, pageCount: 3),
      );

      final containers = find.byType(AnimatedContainer);
      expect(containers, findsNWidgets(3));
    });

    testWidgets('active dot has primary color', (tester) async {
      await pumpTestWidget(
        tester,
        const PageDotIndicator(currentPage: 1, pageCount: 3),
      );

      final containers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );

      final activeDecoration =
          containers.elementAt(1).decoration as BoxDecoration?;
      expect(activeDecoration?.color, isNotNull);
    });

    testWidgets('has Semantics label', (tester) async {
      await pumpTestWidget(
        tester,
        const PageDotIndicator(currentPage: 0, pageCount: 3),
      );

      expect(
        find.bySemanticsLabel(RegExp('onboarding.page_indicator')),
        findsOneWidget,
      );
    });
  });
}
