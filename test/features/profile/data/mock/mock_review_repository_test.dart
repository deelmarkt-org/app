import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/data/mock/mock_review_repository.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';

void main() {
  group('MockReviewRepository', () {
    late MockReviewRepository repository;

    setUp(() {
      repository = MockReviewRepository();
    });

    test('returns 3 mock reviews with default limit', () async {
      final result = await repository.getByUserId('user-001');

      expect(result, isA<List<ReviewEntity>>());
      expect(result.length, 3);
    });

    test('respects limit parameter', () async {
      final limited = await repository.getByUserId('user-001', limit: 2);

      expect(limited.length, 2);
    });

    test('limit of 1 returns single review', () async {
      final result = await repository.getByUserId('user-001', limit: 1);

      expect(result.length, 1);
    });

    test('limit larger than data returns all reviews', () async {
      final result = await repository.getByUserId('user-001', limit: 100);

      expect(result.length, 3);
    });

    test('cursor parameter is accepted but mock ignores it', () async {
      final withCursor = await repository.getByUserId(
        'user-001',
        cursor: 'some-cursor-value',
      );
      final withoutCursor = await repository.getByUserId('user-001');

      expect(withCursor.length, withoutCursor.length);
    });

    test('returned reviews have valid fields', () async {
      final reviews = await repository.getByUserId('user-001');

      for (final review in reviews) {
        expect(review.id, isNotEmpty);
        expect(review.reviewerId, isNotEmpty);
        expect(review.reviewerName, isNotEmpty);
        expect(review.revieweeId, isNotEmpty);
        expect(review.listingId, isNotEmpty);
        expect(review.rating, greaterThanOrEqualTo(1.0));
        expect(review.rating, lessThanOrEqualTo(5.0));
        expect(review.text, isNotEmpty);
      }
    });
  });
}
