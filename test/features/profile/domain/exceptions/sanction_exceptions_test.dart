/// Unit tests for [SanctionException] hierarchy (pure-Dart domain exceptions).
///
/// PostgrestException mapping tests live in
/// test/features/profile/data/supabase/supabase_sanction_repository_test.dart
/// because the mapper is part of the data layer (CLAUDE.md §1.2).
///
/// Reference: lib/features/profile/domain/exceptions/sanction_exceptions.dart
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/domain/exceptions/sanction_exceptions.dart';

void main() {
  group('AppealWindowExpired', () {
    const ex = AppealWindowExpired();

    test('code is APPEAL_WINDOW_EXPIRED', () {
      expect(ex.code, 'APPEAL_WINDOW_EXPIRED');
    });

    test('toString mentions 14-day', () {
      expect(ex.toString(), contains('14-day'));
    });

    test('two instances are equal type', () {
      const a = AppealWindowExpired();
      const b = AppealWindowExpired();
      expect(a.runtimeType, b.runtimeType);
    });

    test('is a SanctionException', () {
      expect(ex, isA<SanctionException>());
    });
  });

  group('AppealAlreadyResolved', () {
    const ex = AppealAlreadyResolved();

    test('code is APPEAL_ALREADY_RESOLVED', () {
      expect(ex.code, 'APPEAL_ALREADY_RESOLVED');
    });

    test('toString mentions final decision', () {
      expect(ex.toString(), contains('final decision'));
    });

    test('is a SanctionException', () {
      expect(ex, isA<SanctionException>());
    });
  });

  group('SanctionNotFound', () {
    const ex = SanctionNotFound();

    test('code is SANCTION_NOT_FOUND', () {
      expect(ex.code, 'SANCTION_NOT_FOUND');
    });

    test('toString mentions no matching sanction', () {
      expect(ex.toString(), contains('no matching sanction'));
    });

    test('is a SanctionException', () {
      expect(ex, isA<SanctionException>());
    });
  });

  group('AppealRateLimited', () {
    const ex = AppealRateLimited();

    test('code is APPEAL_RATE_LIMITED', () {
      expect(ex.code, 'APPEAL_RATE_LIMITED');
    });

    test('toString mentions too many', () {
      expect(ex.toString(), contains('too many'));
    });

    test('is a SanctionException', () {
      expect(ex, isA<SanctionException>());
    });
  });

  group('NetworkFailure', () {
    test('code is NETWORK_FAILURE', () {
      expect(const NetworkFailure().code, 'NETWORK_FAILURE');
    });

    test('stores message', () {
      const ex = NetworkFailure('connection refused');
      expect(ex.message, 'connection refused');
      expect(ex.toString(), contains('connection refused'));
    });

    test('default message is empty string', () {
      expect(const NetworkFailure().message, '');
    });

    test('is a SanctionException', () {
      expect(const NetworkFailure(), isA<SanctionException>());
    });
  });

  group('UnknownSanctionError', () {
    const ex = UnknownSanctionError('some server error');

    test('code is UNKNOWN_SANCTION_ERROR', () {
      expect(ex.code, 'UNKNOWN_SANCTION_ERROR');
    });

    test('stores and exposes message', () {
      expect(ex.message, 'some server error');
    });

    test('toString contains message', () {
      expect(ex.toString(), contains('some server error'));
    });

    test('is a SanctionException', () {
      expect(ex, isA<SanctionException>());
    });
  });
}
