import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/data/mock/mock_review_repository.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';
import 'package:deelmarkt/features/profile/domain/usecases/get_user_reviews_usecase.dart';

void main() {
  group('GetUserReviewsUseCase', () {
    late MockReviewRepository repository;
    late GetUserReviewsUseCase useCase;

    setUp(() {
      repository = MockReviewRepository();
      useCase = GetUserReviewsUseCase(repository);
    });

    test('returns reviews for a user ID', () async {
      final result = await useCase.call('user-001');

      expect(result, isA<List<ReviewEntity>>());
      expect(result, isNotEmpty);
    });

    test('returns review entities with expected fields', () async {
      final result = await useCase.call('user-001');
      final first = result.first;

      expect(first.id, isNotEmpty);
      expect(first.reviewerName, isNotEmpty);
      expect(first.rating, greaterThan(0));
      expect(first.body, isNotEmpty);
    });

    test('respects limit parameter', () async {
      final result = await useCase.call('user-001', limit: 2);

      expect(result.length, lessThanOrEqualTo(2));
    });

    test('accepts cursor parameter', () async {
      final result = await useCase.call('user-001', cursor: 'some-cursor');

      expect(result, isA<List<ReviewEntity>>());
    });
  });
}
