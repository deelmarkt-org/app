import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/data/mock/mock_user_repository.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';

void main() {
  late MockUserRepository repo;

  setUp(() {
    repo = MockUserRepository();
  });

  group('MockUserRepository', () {
    test('getCurrentUser returns a user', () async {
      final user = await repo.getCurrentUser();

      expect(user, isNotNull);
      expect(user!.id, isNotEmpty);
      expect(user.displayName, isNotEmpty);
    });

    test('getById returns user for valid id', () async {
      final user = await repo.getById('user-001');

      expect(user, isNotNull);
      expect(user!.id, 'user-001');
    });

    test('getById returns null for unknown id', () async {
      final user = await repo.getById('unknown-user');

      expect(user, isNull);
    });

    test('updateProfile returns a user', () async {
      final user = await repo.updateProfile(displayName: 'New Name');

      expect(user, isNotNull);
      expect(user.id, isNotEmpty);
    });

    test('mock users have valid KYC levels', () async {
      final user1 = await repo.getById('user-001');
      final user2 = await repo.getById('user-002');

      expect(user1!.kycLevel, KycLevel.level1);
      expect(user2!.kycLevel, KycLevel.level2);
    });

    test('mock users have badges', () async {
      final user = await repo.getById('user-002');

      expect(user!.badges, contains(BadgeType.trustedSeller));
      expect(user.badges, contains(BadgeType.idVerified));
    });
  });
}
