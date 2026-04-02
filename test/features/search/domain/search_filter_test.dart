import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';

void main() {
  group('SearchFilter', () {
    test('empty has no query', () {
      expect(SearchFilter.empty.hasQuery, isFalse);
    });

    test('hasQuery is true for non-empty trimmed query', () {
      const filter = SearchFilter(query: 'fiets');
      expect(filter.hasQuery, isTrue);
    });

    test('hasQuery is false for whitespace-only query', () {
      const filter = SearchFilter(query: '   ');
      expect(filter.hasQuery, isFalse);
    });

    test('hasActiveFilters is false with defaults', () {
      expect(SearchFilter.empty.hasActiveFilters, isFalse);
    });

    test('hasActiveFilters is true with category', () {
      const filter = SearchFilter(categoryId: 'cat-1');
      expect(filter.hasActiveFilters, isTrue);
    });

    test('activeFilterCount counts all active filters', () {
      const filter = SearchFilter(
        categoryId: 'cat-1',
        minPriceCents: 1000,
        condition: ListingCondition.good,
        sortOrder: SearchSortOrder.newest,
      );
      expect(filter.activeFilterCount, 4);
    });

    test('copyWith preserves unchanged fields', () {
      const original = SearchFilter(query: 'fiets', categoryId: 'cat-1');
      final copy = original.copyWith(query: 'auto');
      expect(copy.query, 'auto');
      expect(copy.categoryId, 'cat-1');
    });

    test('copyWith can clear nullable fields', () {
      const filter = SearchFilter(categoryId: 'cat-1');
      final cleared = filter.copyWith(categoryId: () => null);
      expect(cleared.categoryId, isNull);
    });

    test('equality via Equatable', () {
      const a = SearchFilter(query: 'fiets');
      const b = SearchFilter(query: 'fiets');
      expect(a, equals(b));
    });

    test('inequality on different query', () {
      const a = SearchFilter(query: 'fiets');
      const b = SearchFilter(query: 'auto');
      expect(a, isNot(equals(b)));
    });
  });

  group('SearchSortOrder', () {
    test('has 5 values', () {
      expect(SearchSortOrder.values.length, 5);
    });
  });
}
