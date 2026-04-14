/// Unit tests for [SanctionException] hierarchy and [fromPostgrestError] mapping.
///
/// Reference: lib/features/profile/domain/exceptions/sanction_exceptions.dart
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/profile/domain/exceptions/sanction_exceptions.dart';

PostgrestException _pgError(String message, {String? code, dynamic details}) =>
    PostgrestException(message: message, code: code, details: details);

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

  group('SanctionException.fromPostgrestError', () {
    test('maps "14 days" message → AppealWindowExpired', () {
      final result = SanctionException.fromPostgrestError(
        _pgError('appeal window of 14 days has passed'),
      );
      expect(result, isA<AppealWindowExpired>());
    });

    test('maps "14-day" message → AppealWindowExpired', () {
      final result = SanctionException.fromPostgrestError(
        _pgError('The 14-day appeal window is closed'),
      );
      expect(result, isA<AppealWindowExpired>());
    });

    test('case-insensitive 14-day match', () {
      final result = SanctionException.fromPostgrestError(
        _pgError('14 DAY window expired'),
      );
      expect(result, isA<AppealWindowExpired>());
    });

    test('maps "final decision" message → AppealAlreadyResolved', () {
      final result = SanctionException.fromPostgrestError(
        _pgError('A final decision has been made on this appeal'),
      );
      expect(result, isA<AppealAlreadyResolved>());
    });

    test('maps "counter-appeal" message → AppealAlreadyResolved', () {
      final result = SanctionException.fromPostgrestError(
        _pgError('counter-appeal not allowed'),
      );
      expect(result, isA<AppealAlreadyResolved>());
    });

    test('PGRST116 code → SanctionNotFound', () {
      final result = SanctionException.fromPostgrestError(
        _pgError('no rows returned', code: 'PGRST116'),
      );
      expect(result, isA<SanctionNotFound>());
    });

    test('details containing 429 → AppealRateLimited', () {
      final result = SanctionException.fromPostgrestError(
        _pgError('request failed', details: '429 Too Many Requests'),
      );
      expect(result, isA<AppealRateLimited>());
    });

    test('message containing "rate" → AppealRateLimited', () {
      final result = SanctionException.fromPostgrestError(
        _pgError('rate limit exceeded'),
      );
      expect(result, isA<AppealRateLimited>());
    });

    test('unknown message → UnknownSanctionError with original message', () {
      final result = SanctionException.fromPostgrestError(
        _pgError('unexpected server failure'),
      );
      expect(result, isA<UnknownSanctionError>());
      expect(
        (result as UnknownSanctionError).message,
        'unexpected server failure',
      );
    });

    test('PGRST116 takes precedence over generic fallback', () {
      final result = SanctionException.fromPostgrestError(
        _pgError('some message', code: 'PGRST116'),
      );
      expect(result, isA<SanctionNotFound>());
    });

    test('14-day match takes precedence over rate keyword in same message', () {
      // Message with 14-day should win.
      final result = SanctionException.fromPostgrestError(
        _pgError('14-day window rate exceeded'),
      );
      expect(result, isA<AppealWindowExpired>());
    });
  });
}
