import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/widgets/cards/deel_card_skeleton.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_loader.dart';

import 'deel_card_test_helper.dart';

void main() {
  group('DeelCardSkeleton', () {
    testWidgets('grid skeleton renders SkeletonLoader', (tester) async {
      await tester.pumpWidget(buildCardApp(child: const DeelCardSkeleton()));

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('list skeleton renders SkeletonLoader', (tester) async {
      await tester.pumpWidget(
        buildCardApp(
          child: const DeelCardSkeleton(variant: DeelCardVariant.list),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('grid is default variant', (tester) async {
      const skeleton = DeelCardSkeleton();
      expect(skeleton.variant, DeelCardVariant.grid);
    });
  });
}
