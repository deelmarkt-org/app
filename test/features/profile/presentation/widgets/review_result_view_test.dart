import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/review_screen_state.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/review_card.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/review_result_view.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';

import '../../../../helpers/pump_app.dart';

final _review1 = ReviewEntity(
  id: 'r1',
  reviewerId: 'u1',
  reviewerName: 'Alice',
  revieweeId: 'u2',
  listingId: 'l1',
  rating: 4,
  text: 'Great!',
  createdAt: DateTime(2025),
);

final _review2 = ReviewEntity(
  id: 'r2',
  reviewerId: 'u2',
  reviewerName: 'Bob',
  revieweeId: 'u1',
  listingId: 'l1',
  rating: 3,
  text: 'OK',
  createdAt: DateTime(2025),
);

void main() {
  group('ReviewIneligibleView', () {
    testWidgets('renders warning icon and reason key', (tester) async {
      await pumpTestWidget(
        tester,
        const ReviewIneligibleView(reason: 'review.error.ineligible.pending'),
      );

      expect(find.byType(ReviewIneligibleView), findsOneWidget);
      // .tr() returns the key in test environment
      expect(find.text('review.error.ineligible.pending'), findsOneWidget);
    });

    testWidgets('renders with custom reason key', (tester) async {
      await pumpTestWidget(
        tester,
        const ReviewIneligibleView(reason: 'review.error.ineligible.disputed'),
      );

      expect(find.text('review.error.ineligible.disputed'), findsOneWidget);
    });
  });

  group('ReviewSubmittedView', () {
    testWidgets('buyer role renders thank you and waiting text', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const ReviewSubmittedView(role: ReviewRole.buyer),
      );

      expect(find.text('review.thank_you'), findsOneWidget);
      expect(find.text('review.waiting_for_other'), findsOneWidget);
    });

    testWidgets('seller role renders thank you and waiting text', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const ReviewSubmittedView(role: ReviewRole.seller),
      );

      expect(find.text('review.thank_you'), findsOneWidget);
      expect(find.text('review.waiting_for_other'), findsOneWidget);
    });

    testWidgets('has close button', (tester) async {
      await pumpTestWidget(
        tester,
        const ReviewSubmittedView(role: ReviewRole.buyer),
      );

      expect(find.text('review.close'), findsOneWidget);
    });

    testWidgets('close button does not throw', (tester) async {
      await pumpTestWidget(
        tester,
        Builder(
          builder:
              (context) => const ReviewSubmittedView(role: ReviewRole.buyer),
        ),
      );

      // Tap close — pumpTestWidget wraps in MaterialApp so Navigator exists
      await tester.tap(find.text('review.close'));
      await tester.pumpAndSettle();
      // No exception = pass
    });
  });

  group('ReviewBothVisibleView', () {
    testWidgets('renders section header and two review cards', (tester) async {
      await pumpTestWidget(
        tester,
        ReviewBothVisibleView(myReview: _review1, theirReview: _review2),
      );

      expect(find.text('review.both_visible'), findsOneWidget);
      expect(find.byType(ReviewCard), findsNWidgets(2));
    });
  });

  group('ReviewErrorView', () {
    testWidgets('retryable error renders ErrorState widget', (tester) async {
      await pumpTestWidget(
        tester,
        ReviewErrorView(errorClass: ReviewErrorClass.network, onRetry: () {}),
      );

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('non-retryable error renders error message and close button', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const ReviewErrorView(errorClass: ReviewErrorClass.conflict),
      );

      expect(find.byType(ErrorState), findsNothing);
      expect(find.text('review.close'), findsOneWidget);
    });

    testWidgets('rateLimit error with retryAfterSeconds shows message', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        ReviewErrorView(
          errorClass: ReviewErrorClass.rateLimit,
          retryAfterSeconds: 30,
          onRetry: () {},
        ),
      );

      expect(find.byType(ErrorState), findsOneWidget);
    });
  });
}
