import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/domain/entities/seller_stats_entity.dart';

void main() {
  group('SellerStatsEntity', () {
    const entity = SellerStatsEntity(
      totalSalesCents: 124700,
      activeListingsCount: 5,
      unreadMessagesCount: 3,
    );

    test('props includes all fields', () {
      expect(entity.props, [124700, 5, 3]);
    });

    test('equality with same values', () {
      const other = SellerStatsEntity(
        totalSalesCents: 124700,
        activeListingsCount: 5,
        unreadMessagesCount: 3,
      );
      expect(entity, equals(other));
    });

    test('inequality with different totalSalesCents', () {
      const other = SellerStatsEntity(
        totalSalesCents: 0,
        activeListingsCount: 5,
        unreadMessagesCount: 3,
      );
      expect(entity, isNot(equals(other)));
    });

    test('inequality with different activeListingsCount', () {
      const other = SellerStatsEntity(
        totalSalesCents: 124700,
        activeListingsCount: 10,
        unreadMessagesCount: 3,
      );
      expect(entity, isNot(equals(other)));
    });

    test('inequality with different unreadMessagesCount', () {
      const other = SellerStatsEntity(
        totalSalesCents: 124700,
        activeListingsCount: 5,
        unreadMessagesCount: 0,
      );
      expect(entity, isNot(equals(other)));
    });
  });
}
