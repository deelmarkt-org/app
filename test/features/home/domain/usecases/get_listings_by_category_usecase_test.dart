import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/data/mock/mock_category_repository.dart';
import 'package:deelmarkt/features/home/data/mock/mock_listing_repository.dart';
import 'package:deelmarkt/features/home/domain/usecases/get_listings_by_category_usecase.dart';

void main() {
  late GetListingsByCategoryUseCase useCase;

  setUp(() {
    useCase = GetListingsByCategoryUseCase(
      MockListingRepository(),
      MockCategoryRepository(),
    );
  });

  group('GetListingsByCategoryUseCase', () {
    test('returns listings for L2 category ID directly', () async {
      final result = await useCase('cat-phones');

      expect(result, isNotEmpty);
      for (final listing in result) {
        expect(listing.categoryId, 'cat-phones');
      }
    });

    test('expands L1 to L2 children and returns listings', () async {
      final result = await useCase('cat-electronics');

      // Electronics has children: phones, laptops, gaming
      // Mock data has listings in cat-phones and cat-gaming
      expect(result, isNotEmpty);
      final categoryIds = result.map((l) => l.categoryId).toSet();
      // Should contain listings from child categories
      expect(
        categoryIds.intersection({'cat-phones', 'cat-laptops', 'cat-gaming'}),
        isNotEmpty,
      );
    });

    test('respects limit parameter', () async {
      final result = await useCase('cat-electronics', limit: 2);

      expect(result.length, lessThanOrEqualTo(2));
    });

    test('returns empty for category with no listings', () async {
      // cat-tutoring is an L2 with no mock listings
      final result = await useCase('cat-tutoring');

      expect(result, isEmpty);
    });
  });
}
