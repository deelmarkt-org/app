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

    test('getSubcategories returns empty for unknown parent', () async {
      final subs = await repo.getSubcategories('cat-nonexistent');

      expect(subs, isEmpty);
    });

    test('getSubcategories returns L2 for all 8 L1 categories', () async {
      final l1 = await repo.getTopLevel();
      for (final cat in l1) {
        final subs = await repo.getSubcategories(cat.id);
        expect(
          subs,
          isNotEmpty,
          reason: '${cat.name} should have subcategories',
        );
      }
    });
  });

  group('CategoryEntity', () {
    test('equality when all fields match', () {
      const a = CategoryEntity(id: 'c1', name: 'A', icon: 'a');
      const b = CategoryEntity(id: 'c1', name: 'A', icon: 'a');

      expect(a, equals(b));
    });

    test('inequality when fields differ (Riverpod state diffing)', () {
      const a = CategoryEntity(id: 'c1', name: 'A', icon: 'a');
      const b = CategoryEntity(id: 'c1', name: 'B', icon: 'b');

      expect(a, isNot(equals(b)));
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
