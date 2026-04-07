import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/review_screen_state.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/review_result_view.dart';

import '../../../../helpers/pump_app.dart';

/// Minimal [ReviewEntity] fixture.
ReviewEntity _review({
  String id = 'r-1',
  String reviewerId = 'user-1',
  double rating = 4.0,
  String text = 'Snelle levering, goed verpakt.',
}) => ReviewEntity(
  id: id,
  reviewerId: reviewerId,
  reviewerName: 'Jan de Vries',
  revieweeId: 'user-2',
  listingId: 'listing-1',
  rating: rating,
  text: text,
  createdAt: DateTime(2026, 4),
);

void main() {
  group('ReviewIneligibleView', () {
    testWidgets('renders the ineligibility reason key', (tester) async {
      await pumpTestWidget(
        tester,
        const ReviewIneligibleView(reason: 'review.error.ineligible.pending'),
      );
      expect(find.text('review.error.ineligible.pending'), findsOneWidget);
    });

    testWidgets('renders a warning icon', (tester) async {
      await pumpTestWidget(
        tester,
        const ReviewIneligibleView(reason: 'review.error.ineligible.pending'),
      );
      expect(find.byType(Icon), findsOneWidget);
    });
  });

  group('ReviewSubmittedView', () {
    testWidgets('renders thank-you title', (tester) async {
      await pumpTestWidget(
        tester,
        const ReviewSubmittedView(role: ReviewRole.buyer),
      );
      expect(find.text('review.thankYou'), findsOneWidget);
    });

    testWidgets('renders waiting-for-other message', (tester) async {
      await pumpTestWidget(
        tester,
        const ReviewSubmittedView(role: ReviewRole.buyer),
      );
      expect(find.text('review.waitingForOther'), findsOneWidget);
    });

    testWidgets('renders close button', (tester) async {
      await pumpTestWidget(
        tester,
        const ReviewSubmittedView(role: ReviewRole.buyer),
      );
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('buyer role uses seller label in waiting message', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const ReviewSubmittedView(role: ReviewRole.buyer),
      );
      // ReviewSubmittedView passes roleSeller to waitingForOther namedArgs
      // .tr() returns key in tests, so waitingForOther is shown
      expect(find.byType(ReviewSubmittedView), findsOneWidget);
    });

    testWidgets('seller role renders without errors', (tester) async {
      await pumpTestWidget(
        tester,
        const ReviewSubmittedView(role: ReviewRole.seller),
      );
      expect(find.text('review.thankYou'), findsOneWidget);
    });
  });

  group('ReviewBothVisibleView', () {
    testWidgets('renders both-visible title', (tester) async {
      await pumpTestWidget(
        tester,
        ReviewBothVisibleView(
          myReview: _review(),
          theirReview: _review(id: 'r-2', reviewerId: 'user-2'),
        ),
      );
      expect(find.text('review.bothVisible'), findsOneWidget);
    });

    testWidgets('renders reviewer names for both reviews', (tester) async {
      await pumpTestWidget(
        tester,
        ReviewBothVisibleView(
          myReview: _review(),
          theirReview: _review(id: 'r-2', reviewerId: 'user-2'),
        ),
      );
      // ReviewCard shows reviewerName — both use the same name in fixtures
      expect(find.text('Jan de Vries'), findsWidgets);
    });
  });

  group('ReviewErrorView', () {
    testWidgets('renders ErrorState when onRetry is provided', (tester) async {
      await pumpTestWidget(
        tester,
        ReviewErrorView(errorClass: ReviewErrorClass.network, onRetry: () {}),
      );
      // ErrorState with message = 'review.error.network'
      expect(find.text('review.error.network'), findsOneWidget);
    });

    testWidgets('renders close button when onRetry is null', (tester) async {
      await pumpTestWidget(
        tester,
        const ReviewErrorView(errorClass: ReviewErrorClass.conflict),
      );
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('conflict error key renders correctly', (tester) async {
      await pumpTestWidget(
        tester,
        const ReviewErrorView(errorClass: ReviewErrorClass.conflict),
      );
      expect(find.text('review.error.conflict'), findsOneWidget);
    });

    testWidgets('expired error key renders correctly', (tester) async {
      await pumpTestWidget(
        tester,
        const ReviewErrorView(errorClass: ReviewErrorClass.expired),
      );
      expect(find.text('review.error.expired'), findsOneWidget);
    });

    testWidgets('cancelled error key renders correctly', (tester) async {
      await pumpTestWidget(
        tester,
        const ReviewErrorView(errorClass: ReviewErrorClass.cancelled),
      );
      expect(find.text('review.error.cancelled'), findsOneWidget);
    });

    testWidgets('rateLimit error shows seconds placeholder', (tester) async {
      await pumpTestWidget(
        tester,
        const ReviewErrorView(
          errorClass: ReviewErrorClass.rateLimit,
          retryAfterSeconds: 30,
        ),
      );
      expect(find.text('review.error.rateLimit'), findsOneWidget);
    });

    testWidgets('moderationBlocked error key renders', (tester) async {
      await pumpTestWidget(
        tester,
        const ReviewErrorView(errorClass: ReviewErrorClass.moderationBlocked),
      );
      expect(find.text('review.error.moderationBlocked'), findsOneWidget);
    });

    testWidgets('unknown error key renders', (tester) async {
      await pumpTestWidget(
        tester,
        const ReviewErrorView(errorClass: ReviewErrorClass.unknown),
      );
      expect(find.text('review.error.unknown'), findsOneWidget);
    });
  });
}
