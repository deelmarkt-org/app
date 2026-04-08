import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/review_card.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/reviews_tab_view.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_loader.dart';

import '../../../../helpers/pump_app.dart';

/// Wraps widget in MaterialApp without pumpAndSettle (for shimmer animations).
Widget _wrapWidget(Widget child) {
  return MaterialApp(
    theme: DeelmarktTheme.light,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

ReviewEntity _review(String id) => ReviewEntity(
  id: id,
  reviewerId: 'u1',
  reviewerName: 'Alice',
  revieweeId: 'u2',
  listingId: 'l1',
  rating: 4,
  text: 'Great!',
  createdAt: DateTime(2025),
);

void main() {
  group('ReviewsTabView', () {
    testWidgets('loading state shows SkeletonLoader', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          ReviewsTabView(
            reviews: const AsyncValue<List<ReviewEntity>>.loading(),
            onRetry: () {},
          ),
        ),
      );
      // SkeletonLoader has infinite animation — use pump() not pumpAndSettle().
      await tester.pump();

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('empty data shows no-reviews text', (tester) async {
      await pumpTestWidget(
        tester,
        ReviewsTabView(
          reviews: const AsyncValue<List<ReviewEntity>>.data([]),
          onRetry: () {},
        ),
      );

      // .tr() returns the key path in tests.
      expect(find.text('profile.no_reviews'), findsOneWidget);
    });

    testWidgets('error state shows ErrorState', (tester) async {
      await pumpTestWidget(
        tester,
        ReviewsTabView(
          reviews: AsyncValue<List<ReviewEntity>>.error(
            Exception('fail'),
            StackTrace.current,
          ),
          onRetry: () {},
        ),
      );

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('data state with items shows ReviewCard widgets', (
      tester,
    ) async {
      final reviews = [
        ReviewEntity(
          id: 'r1',
          reviewerId: 'u2',
          reviewerName: 'Maria Jansen',
          revieweeId: 'u1',
          listingId: 'l1',
          rating: 5.0,
          text: 'Top verkoper!',
          createdAt: DateTime(2026, 3, 15),
        ),
        ReviewEntity(
          id: 'r2',
          reviewerId: 'u3',
          reviewerName: 'Pieter Bakker',
          revieweeId: 'u1',
          listingId: 'l2',
          rating: 4.0,
          text: 'Goede communicatie.',
          createdAt: DateTime(2026, 3, 10),
        ),
      ];

      await pumpTestWidget(
        tester,
        ReviewsTabView(
          reviews: AsyncValue<List<ReviewEntity>>.data(reviews),
          onRetry: () {},
        ),
      );

      expect(find.byType(ReviewCard), findsNWidgets(2));
      expect(find.text('Maria Jansen'), findsOneWidget);
      expect(find.text('Pieter Bakker'), findsOneWidget);
    });

    testWidgets('data state shows review text', (tester) async {
      final reviews = [
        ReviewEntity(
          id: 'r1',
          reviewerId: 'u2',
          reviewerName: 'Test User',
          revieweeId: 'u1',
          listingId: 'l1',
          rating: 3.0,
          text: 'Okay transaction',
          createdAt: DateTime(2026),
        ),
      ];

      await pumpTestWidget(
        tester,
        ReviewsTabView(
          reviews: AsyncValue<List<ReviewEntity>>.data(reviews),
          onRetry: () {},
        ),
      );

      expect(find.text('Okay transaction'), findsOneWidget);
    });

    testWidgets('shows load more button when hasMore and not loading', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        ReviewsTabView(
          reviews: AsyncValue<List<ReviewEntity>>.data([_review('r1')]),
          onRetry: () {},
          onLoadMore: () {},
          hasMore: true,
        ),
      );

      expect(find.text('seller_profile.load_more'), findsOneWidget);
    });

    testWidgets('hides load more button when isLoadingMore is true', (
      tester,
    ) async {
      // pumpAndSettle would loop forever on CircularProgressIndicator (infinite
      // animation) — use pumpTestWidgetAnimated + manual pump instead.
      await pumpTestWidgetAnimated(
        tester,
        ReviewsTabView(
          reviews: AsyncValue<List<ReviewEntity>>.data([_review('r1')]),
          onRetry: () {},
          onLoadMore: () {},
          hasMore: true,
          isLoadingMore: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('seller_profile.load_more'), findsNothing);
    });
  });
}
