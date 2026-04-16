import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/profile/data/supabase/supabase_sanction_repository.dart';
import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';
import 'package:deelmarkt/features/profile/domain/exceptions/sanction_exceptions.dart';

PostgrestException _pgError(String message, {String? code, dynamic details}) =>
    PostgrestException(message: message, code: code, details: details);

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

  // Mapping tests moved from domain layer — the mapper lives in the data layer
  // (CLAUDE.md §1.2: domain must be pure Dart, no Supabase imports).
  group('mapSanctionError', () {
    test('maps "14 days" message → AppealWindowExpired', () {
      final result = SupabaseSanctionRepository.mapSanctionError(
        _pgError('appeal window of 14 days has passed'),
      );
      expect(result, isA<AppealWindowExpired>());
    });

    test('maps "14-day" message → AppealWindowExpired', () {
      final result = SupabaseSanctionRepository.mapSanctionError(
        _pgError('The 14-day appeal window is closed'),
      );
      expect(result, isA<AppealWindowExpired>());
    });

    test('case-insensitive 14-day match', () {
      final result = SupabaseSanctionRepository.mapSanctionError(
        _pgError('14 DAY window expired'),
      );
      expect(result, isA<AppealWindowExpired>());
    });

    test('maps "final decision" message → AppealAlreadyResolved', () {
      final result = SupabaseSanctionRepository.mapSanctionError(
        _pgError('A final decision has been made on this appeal'),
      );
      expect(result, isA<AppealAlreadyResolved>());
    });

    test('maps "counter-appeal" message → AppealAlreadyResolved', () {
      final result = SupabaseSanctionRepository.mapSanctionError(
        _pgError('counter-appeal not allowed'),
      );
      expect(result, isA<AppealAlreadyResolved>());
    });

    test('PGRST116 code → SanctionNotFound', () {
      final result = SupabaseSanctionRepository.mapSanctionError(
        _pgError('no rows returned', code: 'PGRST116'),
      );
      expect(result, isA<SanctionNotFound>());
    });

    test('details containing 429 → AppealRateLimited', () {
      final result = SupabaseSanctionRepository.mapSanctionError(
        _pgError('request failed', details: '429 Too Many Requests'),
      );
      expect(result, isA<AppealRateLimited>());
    });

    test('message containing "rate" → AppealRateLimited', () {
      final result = SupabaseSanctionRepository.mapSanctionError(
        _pgError('rate limit exceeded'),
      );
      expect(result, isA<AppealRateLimited>());
    });

    test('unknown message → UnknownSanctionError with original message', () {
      final result = SupabaseSanctionRepository.mapSanctionError(
        _pgError('unexpected server failure'),
      );
      expect(result, isA<UnknownSanctionError>());
      expect(
        (result as UnknownSanctionError).message,
        'unexpected server failure',
      );
    });

    test('PGRST116 takes precedence over generic fallback', () {
      final result = SupabaseSanctionRepository.mapSanctionError(
        _pgError('some message', code: 'PGRST116'),
      );
      expect(result, isA<SanctionNotFound>());
    });

    test('14-day match takes precedence over rate keyword in same message', () {
      final result = SupabaseSanctionRepository.mapSanctionError(
        _pgError('14-day window rate exceeded'),
      );
      expect(result, isA<AppealWindowExpired>());
    });
  });
}
