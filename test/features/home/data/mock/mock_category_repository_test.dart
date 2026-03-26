import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/data/mock/mock_category_repository.dart';
import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';

void main() {
  late MockCategoryRepository repo;

  setUp(() {
    repo = MockCategoryRepository();
  });

  group('MockCategoryRepository', () {
    test('getTopLevel returns 8 L1 categories', () async {
      final categories = await repo.getTopLevel();

      expect(categories.length, equals(8));
      for (final cat in categories) {
        expect(cat.isTopLevel, isTrue);
        expect(cat.parentId, isNull);
      }
    });

    test('L1 categories have expected names', () async {
      final categories = await repo.getTopLevel();
      final names = categories.map((c) => c.name).toList();

      expect(names, contains('Voertuigen'));
      expect(names, contains('Elektronica'));
      expect(names, contains('Kleding & Mode'));
    });

    test('getSubcategories returns L2 for electronics', () async {
      final subs = await repo.getSubcategories('cat-electronics');

      expect(subs, isNotEmpty);
      for (final sub in subs) {
        expect(sub.parentId, equals('cat-electronics'));
        expect(sub.isTopLevel, isFalse);
      }
    });

    test('getSubcategories returns empty for category with no subs', () async {
      final subs = await repo.getSubcategories('cat-services');

      expect(subs, isEmpty);
    });
  });

  group('CategoryEntity', () {
    test('equality by id', () {
      const a = CategoryEntity(id: 'c1', name: 'A', icon: 'a');
      const b = CategoryEntity(id: 'c1', name: 'B', icon: 'b');

      expect(a, equals(b));
    });

    test('isTopLevel when parentId is null', () {
      const cat = CategoryEntity(id: 'c1', name: 'Test', icon: 'test');

      expect(cat.isTopLevel, isTrue);
    });

    test('is not top level when parentId set', () {
      const cat = CategoryEntity(
        id: 'c2',
        name: 'Sub',
        icon: 'sub',
        parentId: 'c1',
      );

      expect(cat.isTopLevel, isFalse);
    });
  });
}
