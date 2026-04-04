import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/data/mock/mock_category_repository.dart';
import 'package:deelmarkt/features/home/domain/usecases/get_subcategories_usecase.dart';

void main() {
  late GetSubcategoriesUseCase useCase;

  setUp(() {
    useCase = GetSubcategoriesUseCase(MockCategoryRepository());
  });

  group('GetSubcategoriesUseCase', () {
    test('returns L2 subcategories for valid L1 parent', () async {
      final result = await useCase('cat-electronics');

      expect(result, hasLength(3));
      expect(
        result.map((c) => c.id),
        containsAll(['cat-phones', 'cat-laptops', 'cat-gaming']),
      );
      for (final sub in result) {
        expect(sub.parentId, 'cat-electronics');
      }
    });

    test('returns empty list for unknown parent', () async {
      final result = await useCase('cat-nonexistent');

      expect(result, isEmpty);
    });

    test('returns empty list for L2 ID (no grandchildren)', () async {
      final result = await useCase('cat-phones');

      expect(result, isEmpty);
    });

    test('returns 4 subcategories for vehicles', () async {
      final result = await useCase('cat-vehicles');

      expect(result, hasLength(4));
      expect(
        result.map((c) => c.id),
        containsAll([
          'cat-cars',
          'cat-motorcycles',
          'cat-scooters',
          'cat-parts',
        ]),
      );
    });
  });
}
