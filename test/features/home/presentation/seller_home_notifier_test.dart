import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/domain/entities/action_item_entity.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/domain/entities/seller_stats_entity.dart';
import 'package:deelmarkt/features/home/presentation/seller_home_notifier.dart';

void main() {
  group('SellerHomeState', () {
    const stats = SellerStatsEntity(
      totalSalesCents: 10000,
      activeListingsCount: 3,
      unreadMessagesCount: 1,
    );

    final listing = ListingEntity(
      id: '1',
      title: 'Test',
      description: 'Desc',
      priceInCents: 5000,
      sellerId: 'seller-1',
      sellerName: 'Seller',
      condition: ListingCondition.good,
      categoryId: 'cat-1',
      imageUrls: const [],
      createdAt: DateTime(2026),
    );

    test('isEmpty returns true when listings is empty', () {
      const state = SellerHomeState(
        userName: 'Test',
        stats: stats,
        actions: [],
        listings: [],
      );
      expect(state.isEmpty, isTrue);
    });

    test('isEmpty returns false when listings is non-empty', () {
      final state = SellerHomeState(
        userName: 'Test',
        stats: stats,
        actions: const [],
        listings: [listing],
      );
      expect(state.isEmpty, isFalse);
    });

    test('equality via Equatable', () {
      const a = SellerHomeState(
        userName: 'Test',
        stats: stats,
        actions: [],
        listings: [],
      );
      const b = SellerHomeState(
        userName: 'Test',
        stats: stats,
        actions: [],
        listings: [],
      );
      expect(a, equals(b));
    });

    test('inequality with different userName', () {
      const a = SellerHomeState(
        userName: 'Alice',
        stats: stats,
        actions: [],
        listings: [],
      );
      const b = SellerHomeState(
        userName: 'Bob',
        stats: stats,
        actions: [],
        listings: [],
      );
      expect(a, isNot(equals(b)));
    });

    test('props includes all fields', () {
      final actions = [
        const ActionItemEntity(
          id: 'a1',
          type: ActionItemType.shipOrder,
          title: 'Ship',
          subtitle: 'Sub',
          referenceId: 'ref',
        ),
      ];

      final state = SellerHomeState(
        userName: 'Test',
        stats: stats,
        actions: actions,
        listings: [listing],
      );

      expect(state.props.length, 4);
    });
  });
}
