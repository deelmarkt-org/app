import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/widgets/feedback/skeleton_listing_card.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_shapes.dart';

import 'feedback_test_helper.dart';

void main() {
  group('SkeletonListingCard', () {
    testWidgets('renders without overflow inside a bounded grid cell', (
      tester,
    ) async {
      // Simulate a SliverGrid cell with childAspectRatio 0.7 at 193×275 px.
      await tester.pumpWidget(
        buildFeedbackApp(
          disableAnimations: true,
          child: const SizedBox(
            width: 193,
            height: 275,
            child: SkeletonListingCard(),
          ),
        ),
      );

      // No RenderFlex overflow should be thrown.
      expect(tester.takeException(), isNull);
    });

    testWidgets('contains image, price, title, and seller placeholders', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildFeedbackApp(
          disableAnimations: true,
          child: const SizedBox(
            width: 200,
            height: 300,
            child: SkeletonListingCard(),
          ),
        ),
      );

      // Image + at least 2 lines (price + title) + 1 circle (avatar).
      expect(find.byType(SkeletonBox), findsAtLeastNWidgets(1));
      expect(find.byType(SkeletonLine), findsAtLeastNWidgets(2));
      expect(find.byType(SkeletonCircle), findsOneWidget);
    });

    testWidgets('fills given height via Expanded image', (tester) async {
      const testHeight = 280.0;

      await tester.pumpWidget(
        buildFeedbackApp(
          disableAnimations: true,
          child: const SizedBox(
            width: 200,
            height: testHeight,
            child: SkeletonListingCard(),
          ),
        ),
      );

      final card = tester.getSize(find.byType(SkeletonListingCard));
      expect(card.height, closeTo(testHeight, 1.0));
    });
  });
}
