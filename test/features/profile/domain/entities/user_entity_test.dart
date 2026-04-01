import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';

void main() {
  group('UserEntity', () {
    test('equality when all fields match', () {
      final a = UserEntity(
        id: 'u1',
        displayName: 'Alice',
        kycLevel: KycLevel.level0,
        createdAt: DateTime(2026),
      );
      final b = UserEntity(
        id: 'u1',
        displayName: 'Alice',
        kycLevel: KycLevel.level0,
        createdAt: DateTime(2026),
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality when fields differ (Riverpod state diffing)', () {
      final a = UserEntity(
        id: 'u1',
        displayName: 'Alice',
        kycLevel: KycLevel.level0,
        createdAt: DateTime(2026),
      );
      final b = UserEntity(
        id: 'u1',
        displayName: 'Alice',
        kycLevel: KycLevel.level2,
        createdAt: DateTime(2026),
      );

      expect(a, isNot(equals(b)));
    });

    test('inequality by different id', () {
      final a = UserEntity(
        id: 'u1',
        displayName: 'Alice',
        kycLevel: KycLevel.level0,
        createdAt: DateTime(2026),
      );
      final b = UserEntity(
        id: 'u2',
        displayName: 'Alice',
        kycLevel: KycLevel.level0,
        createdAt: DateTime(2026),
      );

      expect(a, isNot(equals(b)));
    });

    test('default badges is empty', () {
      final user = UserEntity(
        id: 'u1',
        displayName: 'Test',
        kycLevel: KycLevel.level0,
        createdAt: DateTime(2026),
      );

      expect(user.badges, isEmpty);
    });

    test('nullable fields default to null', () {
      final user = UserEntity(
        id: 'u1',
        displayName: 'Test',
        kycLevel: KycLevel.level0,
        createdAt: DateTime(2026),
      );

      expect(user.avatarUrl, isNull);
      expect(user.location, isNull);
      expect(user.averageRating, isNull);
      expect(user.responseTimeMinutes, isNull);
    });
  });

  group('UserEntity copyWith', () {
    final base = UserEntity(
      id: 'u1',
      displayName: 'Alice',
      kycLevel: KycLevel.level0,
      createdAt: DateTime(2026),
      avatarUrl: 'https://example.com/avatar.png',
      location: 'Amsterdam',
      badges: const [BadgeType.emailVerified],
      averageRating: 4.5,
      reviewCount: 10,
      responseTimeMinutes: 30,
    );

    test('returns identical entity when no fields overridden', () {
      expect(base.copyWith(), equals(base));
    });

    test('overrides displayName', () {
      final updated = base.copyWith(displayName: 'Bob');
      expect(updated.displayName, 'Bob');
      expect(updated.id, base.id);
    });

    test('overrides kycLevel', () {
      final updated = base.copyWith(kycLevel: KycLevel.level4);
      expect(updated.kycLevel, KycLevel.level4);
    });

    test('overrides badges', () {
      final updated = base.copyWith(
        badges: [BadgeType.trustedSeller, BadgeType.topRated],
      );
      expect(updated.badges, [BadgeType.trustedSeller, BadgeType.topRated]);
    });

    test('overrides multiple fields at once', () {
      final updated = base.copyWith(
        displayName: 'Charlie',
        reviewCount: 99,
        averageRating: 5.0,
      );
      expect(updated.displayName, 'Charlie');
      expect(updated.reviewCount, 99);
      expect(updated.averageRating, 5.0);
      expect(updated.location, base.location);
    });
  });

  group('KycLevel', () {
    test('has 5 levels', () {
      expect(KycLevel.values.length, equals(5));
    });

    test('values are in order', () {
      expect(KycLevel.values, [
        KycLevel.level0,
        KycLevel.level1,
        KycLevel.level2,
        KycLevel.level3,
        KycLevel.level4,
      ]);
    });
  });

  group('BadgeType', () {
    test('has 7 types', () {
      expect(BadgeType.values.length, equals(7));
    });

    test('fromDbList parses valid strings', () {
      final badges = BadgeType.fromDbList([
        'emailVerified',
        'phoneVerified',
        'trustedSeller',
      ]);
      expect(badges, [
        BadgeType.emailVerified,
        BadgeType.phoneVerified,
        BadgeType.trustedSeller,
      ]);
    });

    test('fromDbList skips unknown values', () {
      final badges = BadgeType.fromDbList([
        'emailVerified',
        'unknownBadge',
        'topRated',
      ]);
      expect(badges, [BadgeType.emailVerified, BadgeType.topRated]);
    });

    test('fromDbList skips non-string values', () {
      final badges = BadgeType.fromDbList([
        'emailVerified',
        123,
        null,
        'fastResponder',
      ]);
      expect(badges, [BadgeType.emailVerified, BadgeType.fastResponder]);
    });

    test('fromDbList returns empty for empty input', () {
      expect(BadgeType.fromDbList([]), isEmpty);
    });

    test('toDbList converts to name strings', () {
      final result = BadgeType.toDbList([
        BadgeType.emailVerified,
        BadgeType.idVerified,
        BadgeType.newUser,
      ]);
      expect(result, ['emailVerified', 'idVerified', 'newUser']);
    });

    test('roundtrip: toDbList then fromDbList returns same badges', () {
      final original = [
        BadgeType.emailVerified,
        BadgeType.phoneVerified,
        BadgeType.topRated,
      ];
      final dbList = BadgeType.toDbList(original);
      final restored = BadgeType.fromDbList(dbList);
      expect(restored, original);
    });
  });
}
