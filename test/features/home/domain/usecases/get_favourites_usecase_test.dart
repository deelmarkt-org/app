import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/data/mock/mock_listing_repository.dart';
import 'package:deelmarkt/features/home/domain/usecases/get_favourites_usecase.dart';

void main() {
  group('GetFavouritesUseCase', () {
    late MockListingRepository repo;
    late GetFavouritesUseCase useCase;

    setUp(() {
      repo = MockListingRepository();
      useCase = GetFavouritesUseCase(repo);
    });

    test('returns empty list when no favourites exist', () async {
      final result = await useCase();
      expect(result, isEmpty);
    });

    test('returns single favourited listing after toggle', () async {
      await repo.toggleFavourite('listing-001');

      final result = await useCase();

      expect(result, hasLength(1));
      expect(result.first.id, 'listing-001');
    });

    test('returns multiple favourited listings', () async {
      await repo.toggleFavourite('listing-001');
      await repo.toggleFavourite('listing-003');

      final result = await useCase();

      expect(result, hasLength(2));
      final ids = result.map((l) => l.id).toSet();
      expect(ids, containsAll(['listing-001', 'listing-003']));
    });

    test('un-toggling a favourite removes it from results', () async {
      await repo.toggleFavourite('listing-001');
      await repo.toggleFavourite('listing-002');
      // Un-toggle listing-001
      await repo.toggleFavourite('listing-001');

      final result = await useCase();

      expect(result, hasLength(1));
      expect(result.first.id, 'listing-002');
    });

    test('delegates to repository getFavourites method', () async {
      // Directly set favouriteIds via @visibleForTesting field
      repo.favouriteIds = {'listing-005'};

      final result = await useCase();

      expect(result, hasLength(1));
      expect(result.first.id, 'listing-005');
    });
  });
}
