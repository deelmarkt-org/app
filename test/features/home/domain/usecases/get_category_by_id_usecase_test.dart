import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/data/mock/mock_category_repository.dart';
import 'package:deelmarkt/features/home/domain/usecases/get_category_by_id_usecase.dart';

void main() {
  late GetCategoryByIdUseCase useCase;

  setUp(() {
    useCase = GetCategoryByIdUseCase(MockCategoryRepository());
  });

  group('GetCategoryByIdUseCase', () {
    test('returns L1 category by ID', () async {
      final result = await useCase('cat-electronics');

      expect(result, isNotNull);
      expect(result!.id, 'cat-electronics');
      expect(result.name, 'Elektronica');
      expect(result.isTopLevel, isTrue);
    });

    test('returns L2 category by ID', () async {
      final result = await useCase('cat-phones');

      expect(result, isNotNull);
      expect(result!.id, 'cat-phones');
      expect(result.name, 'Telefoons');
      expect(result.parentId, 'cat-electronics');
      expect(result.isTopLevel, isFalse);
    });

    test('returns null for unknown ID', () async {
      final result = await useCase('cat-nonexistent');

      expect(result, isNull);
    });
  });
}
