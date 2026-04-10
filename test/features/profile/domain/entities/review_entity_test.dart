import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';

void main() {
  final createdAt = DateTime(2026, 3, 15);

  ReviewEntity buildReview({
    String id = 'review-001',
    String reviewerId = 'user-002',
    String reviewerName = 'Maria Jansen',
    String revieweeId = 'user-001',
    String listingId = 'listing-001',
    double rating = 5.0,
    String body = 'Great seller!',
    DateTime? createdAtOverride,
    String? reviewerAvatarUrl,
  }) {
    return ReviewEntity(
      id: id,
      reviewerId: reviewerId,
      reviewerName: reviewerName,
      revieweeId: revieweeId,
      listingId: listingId,
      rating: rating,
      body: body,
      createdAt: createdAtOverride ?? createdAt,
      reviewerAvatarUrl: reviewerAvatarUrl,
    );
  }

  group('ReviewEntity Equatable', () {
    test('two reviews with same props are equal', () {
      final a = buildReview();
      final b = buildReview();

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('reviews with different id are not equal', () {
      final a = buildReview();
      final b = buildReview(id: 'review-002');

      expect(a, isNot(equals(b)));
    });

    test('reviews with different reviewerId are not equal', () {
      final a = buildReview();
      final b = buildReview(reviewerId: 'user-003');

      expect(a, isNot(equals(b)));
    });

    test('reviews with different reviewerName are not equal', () {
      final a = buildReview();
      final b = buildReview(reviewerName: 'Pieter Bakker');

      expect(a, isNot(equals(b)));
    });

    test('reviews with different revieweeId are not equal', () {
      final a = buildReview();
      final b = buildReview(revieweeId: 'user-005');

      expect(a, isNot(equals(b)));
    });

    test('reviews with different listingId are not equal', () {
      final a = buildReview();
      final b = buildReview(listingId: 'listing-002');

      expect(a, isNot(equals(b)));
    });

    test('reviews with different rating are not equal', () {
      final a = buildReview();
      final b = buildReview(rating: 4.0);

      expect(a, isNot(equals(b)));
    });

    test('reviews with different text are not equal', () {
      final a = buildReview();
      final b = buildReview(body: 'Good experience.');

      expect(a, isNot(equals(b)));
    });

    test('reviews with different createdAt are not equal', () {
      final a = buildReview(createdAtOverride: DateTime(2026, 3, 15));
      final b = buildReview(createdAtOverride: DateTime(2026, 3, 16));

      expect(a, isNot(equals(b)));
    });

    test('reviews with different reviewerAvatarUrl are not equal', () {
      final a = buildReview();
      final b = buildReview(reviewerAvatarUrl: 'https://example.com/img.jpg');

      expect(a, isNot(equals(b)));
    });
  });

  group('ReviewEntity required fields', () {
    test('all required fields are accessible', () {
      final review = buildReview(
        reviewerAvatarUrl: 'https://example.com/a.jpg',
      );

      expect(review.id, 'review-001');
      expect(review.reviewerId, 'user-002');
      expect(review.reviewerName, 'Maria Jansen');
      expect(review.revieweeId, 'user-001');
      expect(review.listingId, 'listing-001');
      expect(review.rating, 5.0);
      expect(review.body, 'Great seller!');
      expect(review.createdAt, createdAt);
      expect(review.reviewerAvatarUrl, 'https://example.com/a.jpg');
    });

    test('reviewerAvatarUrl defaults to null', () {
      final review = buildReview();

      expect(review.reviewerAvatarUrl, isNull);
    });
  });
}
