import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/data/mock/mock_sanction_repository.dart';
import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';

void main() {
  group('MockSanctionRepository (default — no active sanction)', () {
    late MockSanctionRepository repository;

    setUp(() {
      repository = MockSanctionRepository();
    });

    test('getActiveSanction returns null by default', () async {
      final result = await repository.getActiveSanction('user-001');
      expect(result, isNull);
    });

    test('getAll returns empty list', () async {
      final result = await repository.getAll('user-001');
      expect(result, isEmpty);
    });

    test('submitAppeal returns a SanctionEntity with appealedAt set', () async {
      final result = await repository.submitAppeal(
        'sanction-001',
        'I did not violate any rules',
      );

      expect(result, isA<SanctionEntity>());
      expect(result.id, 'sanction-001');
      expect(result.appealedAt, isNotNull);
      expect(result.appealBody, 'I did not violate any rules');
    });
  });

  group('MockSanctionRepository (with activeForUserId)', () {
    late MockSanctionRepository repository;

    setUp(() {
      repository = MockSanctionRepository(activeForUserId: 'suspended-user');
    });

    test(
      'getActiveSanction returns mock suspension for matching user',
      () async {
        final result = await repository.getActiveSanction('suspended-user');

        expect(result, isNotNull);
        expect(result!.type, SanctionType.suspension);
        expect(result.isActive, true);
      },
    );

    test('getActiveSanction returns null for different user', () async {
      final result = await repository.getActiveSanction('other-user');
      expect(result, isNull);
    });

    test('mock suspension has future expiresAt', () async {
      final result = await repository.getActiveSanction('suspended-user');

      expect(result!.expiresAt, isNotNull);
      expect(result.expiresAt!.isAfter(DateTime.now()), true);
    });
  });
}
