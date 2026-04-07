import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/sell/presentation/widgets/quality_step/quality_score_ring.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('QualityScoreRing', () {
    testWidgets('renders the score text', (tester) async {
      await pumpTestWidget(tester, const QualityScoreRing(score: 78));

      expect(find.text('78'), findsOneWidget);
    });

    testWidgets('shows /100 text', (tester) async {
      await pumpTestWidget(tester, const QualityScoreRing(score: 50));

      expect(find.text('/100'), findsOneWidget);
    });

    testWidgets('has Semantics label with score', (tester) async {
      await pumpTestWidget(tester, const QualityScoreRing(score: 65));

      // Verify Semantics widget exists with the correct label.
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == '65/100',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders CustomPaint for the ring', (tester) async {
      await pumpTestWidget(tester, const QualityScoreRing(score: 42));

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('respects custom size parameter', (tester) async {
      await pumpTestWidget(
        tester,
        const QualityScoreRing(score: 80, size: 200),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == 200 && w.height == 200,
        ),
      );
      expect(sizedBox, isNotNull);
    });
  });
}
