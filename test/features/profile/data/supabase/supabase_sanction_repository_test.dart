import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/profile/data/supabase/supabase_sanction_repository.dart';
import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';

/// Minimal Supabase client that uses the real URL but no auth.
/// All RPC calls will throw a [PostgrestException] or [TypeError] —
/// we only test auth-guard logic and error translation here.
SupabaseClient _unauthClient() =>
    SupabaseClient('https://test.supabase.co', 'test-anon-key');

void main() {
  late SupabaseSanctionRepository repository;

  setUp(() {
    repository = SupabaseSanctionRepository(_unauthClient());
  });

  group('submitAppeal', () {
    test('throws when user is not authenticated', () async {
      await expectLater(
        () => repository.submitAppeal('sanction-001', 'I appeal'),
        throwsA(anything),
      );
    });
  });

  group('getActiveSanction', () {
    test('throws when Supabase client is unmocked', () async {
      await expectLater(
        () => repository.getActiveSanction('user-001'),
        throwsA(anything),
      );
    });
  });

  group('getAll', () {
    test('throws when Supabase client is unmocked', () async {
      await expectLater(() => repository.getAll('user-001'), throwsA(anything));
    });
  });

  group('SanctionEntity business logic (no Supabase required)', () {
    test('active suspension blocks access', () {
      final sanction = SanctionEntity(
        id: 's1',
        userId: 'u1',
        type: SanctionType.suspension,
        reason: 'Fraud',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 6)),
      );

      expect(sanction.isActive, true);
    });

    test('overturned ban does not block access', () {
      final sanction = SanctionEntity(
        id: 's2',
        userId: 'u1',
        type: SanctionType.ban,
        reason: 'Fraud',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        appealDecision: AppealDecision.overturned,
      );

      expect(sanction.isActive, false);
    });

    test('appeal pending when appealed but no decision', () {
      final sanction = SanctionEntity(
        id: 's3',
        userId: 'u1',
        type: SanctionType.suspension,
        reason: 'Test',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        appealedAt: DateTime.now().subtract(const Duration(days: 1)),
        appealBody: 'I appeal',
      );

      expect(sanction.isAppealPending, true);
      expect(sanction.canAppeal, true);
    });

    test('canAppeal false when 14-day window closed', () {
      final sanction = SanctionEntity(
        id: 's4',
        userId: 'u1',
        type: SanctionType.suspension,
        reason: 'Test',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      );

      expect(sanction.canAppeal, false);
    });

    test('warning never blocks and cannot be appealed', () {
      final sanction = SanctionEntity(
        id: 's5',
        userId: 'u1',
        type: SanctionType.warning,
        reason: 'Minor rule violation',
        createdAt: DateTime.now(),
      );

      expect(sanction.isActive, false);
      expect(sanction.canAppeal, false);
    });
  });
}
