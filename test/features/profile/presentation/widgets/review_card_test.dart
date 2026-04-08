import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/review_card.dart';
import 'package:deelmarkt/widgets/badges/deel_avatar.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  final testReview = ReviewEntity(
    id: 'review-001',
    reviewerId: 'user-002',
    reviewerName: 'Maria Jansen',
    revieweeId: 'user-001',
    listingId: 'listing-001',
    rating: 4.0,
    text: 'Snelle verzending en precies zoals beschreven.',
    createdAt: DateTime(2026, 3, 15),
  );

  group('ReviewCard', () {
    testWidgets('renders reviewer name', (tester) async {
      await pumpTestWidget(tester, ReviewCard(review: testReview));

      expect(find.text('Maria Jansen'), findsOneWidget);
    });

    testWidgets('renders review text', (tester) async {
      await pumpTestWidget(tester, ReviewCard(review: testReview));

      expect(
        find.text('Snelle verzending en precies zoals beschreven.'),
        findsOneWidget,
      );
    });

    testWidgets('shows star rating with 5 star icons', (tester) async {
      await pumpTestWidget(tester, ReviewCard(review: testReview));

      expect(find.byType(Icon), findsNWidgets(5));
    });

    testWidgets('shows reviewer avatar', (tester) async {
      await pumpTestWidget(tester, ReviewCard(review: testReview));

      final avatar = tester.widget<DeelAvatar>(find.byType(DeelAvatar));
      expect(avatar.displayName, 'Maria Jansen');
      expect(avatar.size, DeelAvatarSize.small);
    });

    testWidgets('avatar passes imageUrl when provided', (tester) async {
      final reviewWithAvatar = ReviewEntity(
        id: 'review-002',
        reviewerId: 'user-003',
        reviewerName: 'Pieter Bakker',
        revieweeId: 'user-001',
        listingId: 'listing-002',
        rating: 5.0,
        text: 'Great!',
        createdAt: DateTime(2026, 3, 10),
        reviewerAvatarUrl: 'https://example.com/pieter.jpg',
      );

      await pumpTestWidget(tester, ReviewCard(review: reviewWithAvatar));

      final avatar = tester.widget<DeelAvatar>(find.byType(DeelAvatar));
      expect(avatar.imageUrl, 'https://example.com/pieter.jpg');
    });

    testWidgets('has star rating semantics', (tester) async {
      await pumpTestWidget(tester, ReviewCard(review: testReview));

      // Without EasyLocalization, .tr() returns the key path
      expect(find.bySemanticsLabel('review.a11y.rating_label'), findsOneWidget);
    });
  });
}
