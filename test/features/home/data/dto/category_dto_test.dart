import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/data/dto/category_dto.dart';

void main() {
  group('CategoryDto', () {
    test('fromJson parses L1 category', () {
      final json = {
        'id': 'c1000000-0000-0000-0000-000000000001',
        'name': 'Electronics',
        'name_nl': 'Elektronica',
        'icon': 'device-mobile',
        'parent_id': null,
        'listing_count': 42,
      };

      final entity = CategoryDto.fromJson(json);

      expect(entity.id, 'c1000000-0000-0000-0000-000000000001');
      expect(entity.name, 'Elektronica'); // Dutch name preferred
      expect(entity.icon, 'device-mobile');
      expect(entity.parentId, isNull);
      expect(entity.isTopLevel, true);
      expect(entity.listingCount, 42);
    });

    test('fromJson parses L2 subcategory', () {
      final json = {
        'id': 'sub-001',
        'name': 'Phones',
        'name_nl': 'Telefoons',
        'icon': 'device-mobile',
        'parent_id': 'c1000000-0000-0000-0000-000000000001',
        'listing_count': 15,
      };

      final entity = CategoryDto.fromJson(json);

      expect(entity.parentId, 'c1000000-0000-0000-0000-000000000001');
      expect(entity.isTopLevel, false);
    });

    test('fromJson defaults listing_count to 0', () {
      final json = {
        'id': 'cat-001',
        'name': 'Test',
        'name_nl': 'Test',
        'icon': 'star',
        'parent_id': null,
      };

      final entity = CategoryDto.fromJson(json);
      expect(entity.listingCount, 0);
    });

    test('fromJson falls back to English name when name_nl is null', () {
      final json = {
        'id': 'cat-002',
        'name': 'Electronics',
        'name_nl': null,
        'icon': 'device-mobile',
        'parent_id': null,
      };

      final entity = CategoryDto.fromJson(json);
      expect(entity.name, 'Electronics');
    });

    test('fromJsonList parses multiple categories', () {
      final list = CategoryDto.fromJsonList([
        {
          'id': '1',
          'name': 'A',
          'name_nl': 'A',
          'icon': 'star',
          'parent_id': null,
        },
        {
          'id': '2',
          'name': 'B',
          'name_nl': 'B',
          'icon': 'heart',
          'parent_id': null,
        },
      ]);

      expect(list, hasLength(2));
    });

    test('fromJson throws FormatException on missing id', () {
      expect(() => CategoryDto.fromJson({}), throwsFormatException);
    });

    test('fromJsonList skips non-Map entries', () {
      final list = CategoryDto.fromJsonList([
        {
          'id': '1',
          'name': 'A',
          'name_nl': 'A',
          'icon': 'star',
          'parent_id': null,
        },
        'invalid',
        null,
      ]);
      expect(list, hasLength(1));
    });
  });
}
