import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/data/mock/mock_listing_repository.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/profile/domain/usecases/get_user_listings_usecase.dart';

void main() {
  group('GetUserListingsUseCase', () {
    late MockListingRepository repository;
    late GetUserListingsUseCase useCase;

    setUp(() {
      repository = MockListingRepository();
      useCase = GetUserListingsUseCase(repository);
    });

    test('returns listings for a user ID', () async {
      final result = await useCase.call('user-001');

      expect(result, isA<List<ListingEntity>>());
      expect(result, isNotEmpty);
      expect(result.every((l) => l.sellerId == 'user-001'), isTrue);
    });

    test('returns empty list for unknown user ID', () async {
      final result = await useCase.call('nonexistent-user');

      expect(result, isEmpty);
    });

    test('respects limit parameter', () async {
      final result = await useCase.call('user-001', limit: 1);

      expect(result.length, lessThanOrEqualTo(1));
    });

    test('accepts cursor parameter', () async {
      final result = await useCase.call('user-001', cursor: 'some-cursor');

      expect(result, isA<List<ListingEntity>>());
    });
  });
}
