import 'package:flutter_test/flutter_test.dart';
import 'package:deelmarkt/features/admin/domain/entities/activity_item_entity.dart';

void main() {
  group('ActivityItemType', () {
    test('has exactly 4 values', () {
      expect(ActivityItemType.values.length, equals(4));
    });

    test('contains listingRemoved', () {
      expect(
        ActivityItemType.values,
        contains(ActivityItemType.listingRemoved),
      );
    });

    test('contains userVerified', () {
      expect(ActivityItemType.values, contains(ActivityItemType.userVerified));
    });

    test('contains disputeEscalated', () {
      expect(
        ActivityItemType.values,
        contains(ActivityItemType.disputeEscalated),
      );
    });

    test('contains systemUpdate', () {
      expect(ActivityItemType.values, contains(ActivityItemType.systemUpdate));
    });
  });

  group('ActivityItemEntity', () {
    final timestamp = DateTime(2026, 4, 10, 12);
    const testParams = {'listingId': '4321', 'moderator': 'Moderator A'};

    final entity = ActivityItemEntity(
      id: 'act-001',
      type: ActivityItemType.listingRemoved,
      params: testParams,
      timestamp: timestamp,
    );

    test('two instances with same values are equal', () {
      final other = ActivityItemEntity(
        id: 'act-001',
        type: ActivityItemType.listingRemoved,
        params: testParams,
        timestamp: timestamp,
      );

      expect(entity, equals(other));
    });

    test('different id produces inequality', () {
      final other = ActivityItemEntity(
        id: 'act-999',
        type: ActivityItemType.listingRemoved,
        params: testParams,
        timestamp: timestamp,
      );

      expect(entity, isNot(equals(other)));
    });

    test('different type produces inequality', () {
      final other = ActivityItemEntity(
        id: 'act-001',
        type: ActivityItemType.systemUpdate,
        params: testParams,
        timestamp: timestamp,
      );

      expect(entity, isNot(equals(other)));
    });

    test('different params produces inequality', () {
      final other = ActivityItemEntity(
        id: 'act-001',
        type: ActivityItemType.listingRemoved,
        params: const {'listingId': '9999', 'moderator': 'Other'},
        timestamp: timestamp,
      );

      expect(entity, isNot(equals(other)));
    });

    test('different timestamp produces inequality', () {
      final other = ActivityItemEntity(
        id: 'act-001',
        type: ActivityItemType.listingRemoved,
        params: testParams,
        timestamp: DateTime(2025),
      );

      expect(entity, isNot(equals(other)));
    });

    test('props contains all 4 fields', () {
      expect(entity.props.length, equals(4));
      expect(
        entity.props,
        equals([
          'act-001',
          ActivityItemType.listingRemoved,
          testParams,
          timestamp,
        ]),
      );
    });

    test('empty params map is valid', () {
      final emptyParamsEntity = ActivityItemEntity(
        id: 'act-002',
        type: ActivityItemType.systemUpdate,
        params: const {},
        timestamp: timestamp,
      );

      expect(emptyParamsEntity.params, isEmpty);
    });
  });
}
