import 'package:flutter_test/flutter_test.dart';
import 'package:deelmarkt/features/admin/domain/entities/admin_stats_entity.dart';

void main() {
  group('AdminStatsEntity', () {
    const entity = AdminStatsEntity(
      openDisputes: 5,
      dsaNoticesWithin24h: 3,
      activeListings: 120,
      escrowAmountCents: 1245000,
      flaggedListings: 7,
      reportedUsers: 2,
      approvedCount: 45,
    );

    test('two instances with same values are equal', () {
      const other = AdminStatsEntity(
        openDisputes: 5,
        dsaNoticesWithin24h: 3,
        activeListings: 120,
        escrowAmountCents: 1245000,
        flaggedListings: 7,
        reportedUsers: 2,
        approvedCount: 45,
      );

      expect(entity, equals(other));
    });

    test('different openDisputes produces inequality', () {
      const other = AdminStatsEntity(
        openDisputes: 99,
        dsaNoticesWithin24h: 3,
        activeListings: 120,
        escrowAmountCents: 1245000,
        flaggedListings: 7,
        reportedUsers: 2,
        approvedCount: 45,
      );

      expect(entity, isNot(equals(other)));
    });

    test('different dsaNoticesWithin24h produces inequality', () {
      const other = AdminStatsEntity(
        openDisputes: 5,
        dsaNoticesWithin24h: 99,
        activeListings: 120,
        escrowAmountCents: 1245000,
        flaggedListings: 7,
        reportedUsers: 2,
        approvedCount: 45,
      );

      expect(entity, isNot(equals(other)));
    });

    test('different activeListings produces inequality', () {
      const other = AdminStatsEntity(
        openDisputes: 5,
        dsaNoticesWithin24h: 3,
        activeListings: 99,
        escrowAmountCents: 1245000,
        flaggedListings: 7,
        reportedUsers: 2,
        approvedCount: 45,
      );

      expect(entity, isNot(equals(other)));
    });

    test('different escrowAmountCents produces inequality', () {
      const other = AdminStatsEntity(
        openDisputes: 5,
        dsaNoticesWithin24h: 3,
        activeListings: 120,
        escrowAmountCents: 99,
        flaggedListings: 7,
        reportedUsers: 2,
        approvedCount: 45,
      );

      expect(entity, isNot(equals(other)));
    });

    test('different flaggedListings produces inequality', () {
      const other = AdminStatsEntity(
        openDisputes: 5,
        dsaNoticesWithin24h: 3,
        activeListings: 120,
        escrowAmountCents: 1245000,
        flaggedListings: 99,
        reportedUsers: 2,
        approvedCount: 45,
      );

      expect(entity, isNot(equals(other)));
    });

    test('different reportedUsers produces inequality', () {
      const other = AdminStatsEntity(
        openDisputes: 5,
        dsaNoticesWithin24h: 3,
        activeListings: 120,
        escrowAmountCents: 1245000,
        flaggedListings: 7,
        reportedUsers: 99,
        approvedCount: 45,
      );

      expect(entity, isNot(equals(other)));
    });

    test('different approvedCount produces inequality', () {
      const other = AdminStatsEntity(
        openDisputes: 5,
        dsaNoticesWithin24h: 3,
        activeListings: 120,
        escrowAmountCents: 1245000,
        flaggedListings: 7,
        reportedUsers: 2,
        approvedCount: 99,
      );

      expect(entity, isNot(equals(other)));
    });

    test('props contains all 7 fields', () {
      expect(entity.props.length, equals(7));
      expect(entity.props, equals([5, 3, 120, 1245000, 7, 2, 45]));
    });
  });
}
