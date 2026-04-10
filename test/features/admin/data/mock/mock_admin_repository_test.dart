import 'package:deelmarkt/features/admin/data/mock/mock_admin_repository.dart';
import 'package:deelmarkt/features/admin/domain/entities/activity_item_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockAdminRepository', () {
    late MockAdminRepository repo;

    setUp(() {
      repo = MockAdminRepository();
    });

    group('getStats', () {
      test('returns expected hardcoded values', () async {
        final stats = await repo.getStats();

        expect(stats.openDisputes, 12);
        expect(stats.dsaNoticesWithin24h, 3);
        expect(stats.activeListings, 156);
        expect(stats.escrowAmountCents, 1245000);
        expect(stats.flaggedListings, 8);
        expect(stats.reportedUsers, 4);
        expect(stats.approvedCount, 142);
      });
    });

    group('getRecentActivity', () {
      test('returns 4 items by default', () async {
        final items = await repo.getRecentActivity();

        expect(items, hasLength(4));
      });

      test('respects limit parameter', () async {
        final items = await repo.getRecentActivity(limit: 2);

        expect(items, hasLength(2));
      });

      test('returns all items when limit exceeds total', () async {
        final items = await repo.getRecentActivity(limit: 100);

        expect(items, hasLength(4));
      });

      test('returns empty list when limit is 0', () async {
        final items = await repo.getRecentActivity(limit: 0);

        expect(items, isEmpty);
      });

      test('each activity item has valid id', () async {
        final items = await repo.getRecentActivity();

        for (final item in items) {
          expect(item.id, isNotEmpty);
        }
      });

      test('each activity item has valid type', () async {
        final items = await repo.getRecentActivity();

        expect(items[0].type, ActivityItemType.listingRemoved);
        expect(items[1].type, ActivityItemType.userVerified);
        expect(items[2].type, ActivityItemType.disputeEscalated);
        expect(items[3].type, ActivityItemType.systemUpdate);
      });

      test('each activity item has valid title and subtitle', () async {
        final items = await repo.getRecentActivity();

        for (final item in items) {
          expect(item.title, isNotEmpty);
          expect(item.subtitle, isNotEmpty);
        }
      });

      test('each activity item has a timestamp', () async {
        final items = await repo.getRecentActivity();

        for (final item in items) {
          expect(item.timestamp, isA<DateTime>());
        }
      });

      test('activity items are ordered newest first', () async {
        final items = await repo.getRecentActivity();

        for (var i = 0; i < items.length - 1; i++) {
          expect(
            items[i].timestamp.isAfter(items[i + 1].timestamp),
            isTrue,
            reason: 'Item $i should be newer than item ${i + 1}',
          );
        }
      });
    });
  });
}
