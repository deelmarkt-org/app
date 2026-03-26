import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';

void main() {
  group('UserEntity', () {
    test('equality by id', () {
      final a = UserEntity(
        id: 'u1',
        displayName: 'Alice',
        kycLevel: KycLevel.level0,
        createdAt: DateTime(2026, 1, 1),
      );
      final b = UserEntity(
        id: 'u1',
        displayName: 'Bob',
        kycLevel: KycLevel.level2,
        createdAt: DateTime(2026, 6, 1),
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality by different id', () {
      final a = UserEntity(
        id: 'u1',
        displayName: 'Alice',
        kycLevel: KycLevel.level0,
        createdAt: DateTime(2026, 1, 1),
      );
      final b = UserEntity(
        id: 'u2',
        displayName: 'Alice',
        kycLevel: KycLevel.level0,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(a, isNot(equals(b)));
    });

    test('default badges is empty', () {
      final user = UserEntity(
        id: 'u1',
        displayName: 'Test',
        kycLevel: KycLevel.level0,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(user.badges, isEmpty);
    });

    test('nullable fields default to null', () {
      final user = UserEntity(
        id: 'u1',
        displayName: 'Test',
        kycLevel: KycLevel.level0,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(user.avatarUrl, isNull);
      expect(user.location, isNull);
      expect(user.averageRating, isNull);
      expect(user.responseTimeMinutes, isNull);
    });
  });

  group('KycLevel', () {
    test('has 3 levels', () {
      expect(KycLevel.values.length, equals(3));
    });
  });

  group('BadgeType', () {
    test('has 7 types', () {
      expect(BadgeType.values.length, equals(7));
    });
  });
}
