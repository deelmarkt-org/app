import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_aggregate.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/rating_display.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  final visibleAggregate = ReviewAggregate(
    userId: 'user-001',
    averageRating: 4.8,
    totalCount: 12,
    isVisible: true,
    distribution: const {5: 8, 4: 3, 3: 1},
    lastReviewAt: DateTime(2026, 4, 2),
  );

  final tooFewAggregate = ReviewAggregate(
    userId: 'user-002',
    averageRating: 5.0,
    totalCount: 1,
    isVisible: false,
    distribution: const {5: 1},
    lastReviewAt: DateTime(2026, 3, 20),
  );

  group('RatingDisplay.large', () {
    testWidgets('renders average + stars + count', (tester) async {
      await pumpTestWidget(
        tester,
        RatingDisplay.large(aggregate: visibleAggregate),
      );

      // Stars rendered
      expect(find.byType(Icon), findsNWidgets(5));
      // Count text present (.tr() returns key path)
      expect(find.text('sellerProfile.reviewCount'), findsOneWidget);
    });

    testWidgets('filled stars match rounded average', (tester) async {
      await pumpTestWidget(
        tester,
        RatingDisplay.large(aggregate: visibleAggregate),
      );

      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      // 4.8 rounds to 5 → all 5 filled
      for (final icon in icons) {
        expect(icon.color, DeelmarktColors.warning);
      }
    });

    testWidgets('has Semantics label', (tester) async {
      await pumpTestWidget(
        tester,
        RatingDisplay.large(aggregate: visibleAggregate),
      );

      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'rating.a11y.summary',
        ),
        findsOneWidget,
      );
    });
  });

  group('RatingDisplay.inline', () {
    testWidgets('renders compact stars + count', (tester) async {
      await pumpTestWidget(
        tester,
        RatingDisplay.inline(aggregate: visibleAggregate),
      );

      expect(find.byType(Icon), findsNWidgets(5));
      expect(find.text('(12)'), findsOneWidget);
    });
  });

  group('RatingDisplay.tooFew', () {
    testWidgets('renders info chip', (tester) async {
      await pumpTestWidget(
        tester,
        RatingDisplay.tooFew(aggregate: tooFewAggregate),
      );

      expect(find.text('sellerProfile.tooFewReviews'), findsOneWidget);
      // No stars in tooFew variant
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('uses info colour tokens', (tester) async {
      await pumpTestWidget(
        tester,
        RatingDisplay.tooFew(aggregate: tooFewAggregate),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(RatingDisplay),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, DeelmarktColors.infoSurface);
    });
  });

  group('RatingDisplay.fromAggregate factory', () {
    testWidgets('picks large variant when visible', (tester) async {
      final widget = RatingDisplay.fromAggregate(visibleAggregate);
      await pumpTestWidget(tester, widget);

      // Large shows headlineLarge-style number
      expect(find.byType(Icon), findsNWidgets(5));
      expect(find.text('sellerProfile.reviewCount'), findsOneWidget);
    });

    testWidgets('picks tooFew variant when not visible', (tester) async {
      final widget = RatingDisplay.fromAggregate(tooFewAggregate);
      await pumpTestWidget(tester, widget);

      expect(find.text('sellerProfile.tooFewReviews'), findsOneWidget);
    });
  });

  group('RatingDisplay dark mode', () {
    testWidgets('renders in dark theme without errors', (tester) async {
      await pumpTestWidget(
        tester,
        RatingDisplay.large(aggregate: visibleAggregate),
        theme: DeelmarktTheme.dark,
      );

      expect(find.byType(RatingDisplay), findsOneWidget);
    });
  });
}
