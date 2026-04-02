import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/data/mock/mock_listing_repository.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';
import 'package:deelmarkt/features/search/domain/search_listings_usecase.dart';

void main() {
  late SearchListingsUseCase useCase;

  setUp(() {
    useCase = SearchListingsUseCase(MockListingRepository());
  });

  group('SearchListingsUseCase', () {
    test('returns results matching query', () async {
      const filter = SearchFilter(query: 'fiets');
      final result = await useCase(filter);
      expect(result.listings, isNotEmpty);
      expect(
        result.listings.every(
          (l) =>
              l.title.toLowerCase().contains('fiets') ||
              l.description.toLowerCase().contains('fiets'),
        ),
        isTrue,
      );
    });

    test('returns empty for non-matching query', () async {
      const filter = SearchFilter(query: 'xyznonexistent');
      final result = await useCase(filter);
      expect(result.listings, isEmpty);
    });

    test('applies sort order', () async {
      const filter = SearchFilter(sortOrder: SearchSortOrder.priceLowHigh);
      final result = await useCase(filter);
      if (result.listings.length > 1) {
        for (var i = 0; i < result.listings.length - 1; i++) {
          expect(
            result.listings[i].priceInCents,
            lessThanOrEqualTo(result.listings[i + 1].priceInCents),
          );
        }
      }
    });

    test('respects offset for pagination', () async {
      const filter = SearchFilter();
      final first = await useCase(filter, limit: 2);
      final second = await useCase(filter, offset: 2, limit: 2);
      if (first.listings.isNotEmpty && second.listings.isNotEmpty) {
        expect(first.listings.first.id, isNot(second.listings.first.id));
      }
    });
  });
}
