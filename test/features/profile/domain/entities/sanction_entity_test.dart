import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';

void main() {
  group('SanctionEntity.isActive', () {
    test('warning is never active (never blocks access)', () {
      final warning = SanctionEntity(
        id: 's1',
        userId: 'u1',
        type: SanctionType.warning,
        reason: 'Test',
        createdAt: DateTime.now(),
      );

      expect(warning.isActive, false);
    });

    test('active suspension with no expiry is active', () {
      final suspension = SanctionEntity(
        id: 's2',
        userId: 'u1',
        type: SanctionType.suspension,
        reason: 'Test',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 6)),
      );

      expect(suspension.isActive, true);
    });

    test('expired suspension is not active', () {
      final suspension = SanctionEntity(
        id: 's3',
        userId: 'u1',
        type: SanctionType.suspension,
        reason: 'Test',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        expiresAt: DateTime.now().subtract(const Duration(days: 3)),
      );

      expect(suspension.isActive, false);
    });

    test('overturned suspension is not active', () {
      final suspension = SanctionEntity(
        id: 's4',
        userId: 'u1',
        type: SanctionType.suspension,
        reason: 'Test',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        expiresAt: DateTime.now().add(const Duration(days: 5)),
        appealDecision: AppealDecision.overturned,
      );

      expect(suspension.isActive, false);
    });

    test('upheld suspension remains active', () {
      final suspension = SanctionEntity(
        id: 's5',
        userId: 'u1',
        type: SanctionType.suspension,
        reason: 'Test',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        expiresAt: DateTime.now().add(const Duration(days: 5)),
        appealDecision: AppealDecision.upheld,
      );

      expect(suspension.isActive, true);
    });

    test('permanent ban with no expiry is active', () {
      final ban = SanctionEntity(
        id: 's6',
        userId: 'u1',
        type: SanctionType.ban,
        reason: 'Test',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );

      expect(ban.isActive, true);
    });
  });

  group('SanctionEntity.canAppeal', () {
    test('warning cannot be appealed', () {
      final warning = SanctionEntity(
        id: 's1',
        userId: 'u1',
        type: SanctionType.warning,
        reason: 'Test',
        createdAt: DateTime.now(),
      );

      expect(warning.canAppeal, false);
    });

    test('recent suspension without decision can be appealed', () {
      final suspension = SanctionEntity(
        id: 's2',
        userId: 'u1',
        type: SanctionType.suspension,
        reason: 'Test',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(suspension.canAppeal, true);
    });

    test('suspension older than 14 days cannot be appealed', () {
      final suspension = SanctionEntity(
        id: 's3',
        userId: 'u1',
        type: SanctionType.suspension,
        reason: 'Test',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      );

      expect(suspension.canAppeal, false);
    });

    test('suspension with existing decision cannot be appealed', () {
      final suspension = SanctionEntity(
        id: 's4',
        userId: 'u1',
        type: SanctionType.suspension,
        reason: 'Test',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        appealDecision: AppealDecision.upheld,
      );

      expect(suspension.canAppeal, false);
    });
  });

  group('SanctionEntity.isAppealPending', () {
    test('returns true when appealed but no decision', () {
      final sanction = SanctionEntity(
        id: 's1',
        userId: 'u1',
        type: SanctionType.suspension,
        reason: 'Test',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        appealedAt: DateTime.now(),
        appealBody: 'I appeal this',
      );

      expect(sanction.isAppealPending, true);
    });

    test('returns false when not appealed', () {
      final sanction = SanctionEntity(
        id: 's2',
        userId: 'u1',
        type: SanctionType.suspension,
        reason: 'Test',
        createdAt: DateTime.now(),
      );

      expect(sanction.isAppealPending, false);
    });

    test('returns false when decision has been made', () {
      final sanction = SanctionEntity(
        id: 's3',
        userId: 'u1',
        type: SanctionType.suspension,
        reason: 'Test',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        appealedAt: DateTime.now().subtract(const Duration(days: 2)),
        appealBody: 'I appeal this',
        appealDecision: AppealDecision.upheld,
      );

      expect(sanction.isAppealPending, false);
    });
  });

  group('SanctionEntity equality', () {
    test('two entities with same id are equal', () {
      final a = SanctionEntity(
        id: 'same-id',
        userId: 'u1',
        type: SanctionType.suspension,
        reason: 'Test',
        createdAt: DateTime.now(),
      );
      final b = SanctionEntity(
        id: 'same-id',
        userId: 'u2',
        type: SanctionType.ban,
        reason: 'Different reason',
        createdAt: DateTime.now(),
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('two entities with different ids are not equal', () {
      final a = SanctionEntity(
        id: 'id-a',
        userId: 'u1',
        type: SanctionType.suspension,
        reason: 'Test',
        createdAt: DateTime.now(),
      );
      final b = SanctionEntity(
        id: 'id-b',
        userId: 'u1',
        type: SanctionType.suspension,
        reason: 'Test',
        createdAt: DateTime.now(),
      );

      expect(a, isNot(equals(b)));
    });
  });

  group('SanctionType enum', () {
    test('all values exist', () {
      expect(
        SanctionType.values,
        containsAll([
          SanctionType.warning,
          SanctionType.suspension,
          SanctionType.ban,
        ]),
      );
    });
  });

  group('AppealDecision enum', () {
    test('all values exist', () {
      expect(
        AppealDecision.values,
        containsAll([AppealDecision.upheld, AppealDecision.overturned]),
      );
    });
  });
}
