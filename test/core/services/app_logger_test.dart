import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for [AppLogger] — Tier-1 Audit M-02.
///
/// Since [AppLogger.info], [warning], and [error] use `kDebugMode` and
/// `developer.log` under the hood (which cannot easily be captured in
/// unit tests), we focus on the fully testable [maskPii] helper and
/// ensure the API surface compiles and does not throw.
void main() {
  group('AppLogger.maskPii', () {
    test('masks email addresses', () {
      const input = 'Contact user at jan.de.vries@gmail.com for info';
      final result = AppLogger.maskPii(input);

      expect(result, contains('***@***.***'));
      expect(result, isNot(contains('jan.de.vries@gmail.com')));
    });

    test('masks multiple email addresses', () {
      const input = 'From alice@example.com to bob+test@mail.nl';
      final result = AppLogger.maskPii(input);

      expect('***@***.***'.allMatches(result).length, equals(2));
      expect(result, isNot(contains('alice@example.com')));
      expect(result, isNot(contains('bob+test@mail.nl')));
    });

    test('masks Dutch phone numbers with +31 prefix', () {
      const input = 'Call me at +31612345678';
      final result = AppLogger.maskPii(input);

      expect(result, contains('+31*****'));
      expect(result, isNot(contains('+31612345678')));
    });

    test('masks Dutch phone numbers with 0031 prefix', () {
      const input = 'Phone: 0031612345678';
      final result = AppLogger.maskPii(input);

      expect(result, contains('+31*****'));
      expect(result, isNot(contains('0031612345678')));
    });

    test('masks Dutch mobile numbers starting with 06', () {
      const input = 'Bel 0612345678 voor info';
      final result = AppLogger.maskPii(input);

      expect(result, contains('+31*****'));
      expect(result, isNot(contains('0612345678')));
    });

    test('masks IBAN numbers', () {
      const input = 'Betaal naar NL91ABNA0417164300';
      final result = AppLogger.maskPii(input);

      expect(result, contains('NL**BANK**********'));
      expect(result, isNot(contains('NL91ABNA0417164300')));
    });

    test('masks BSN preceded by label', () {
      const input = 'Gebruiker BSN: 123456789 aangemeld';
      final result = AppLogger.maskPii(input);

      expect(result, contains('BSN: *********'));
      expect(result, isNot(contains('123456789')));
    });

    test('masks BSN case-insensitively', () {
      const input = 'bsn 987654321 gevonden';
      final result = AppLogger.maskPii(input);

      expect(result, contains('BSN: *********'));
      expect(result, isNot(contains('987654321')));
    });

    test('does not mask 9-digit numbers without BSN context', () {
      const input = 'Order 123456789 processed';
      final result = AppLogger.maskPii(input);

      expect(result, contains('123456789'));
    });

    test('masks multiple PII types in one string', () {
      const input = 'User jan@test.nl (+31612345678) IBAN: NL91ABNA0417164300';
      final result = AppLogger.maskPii(input);

      expect(result, isNot(contains('jan@test.nl')));
      expect(result, isNot(contains('+31612345678')));
      expect(result, isNot(contains('NL91ABNA0417164300')));
    });

    test('returns unchanged string when no PII present', () {
      const input = 'Transaction TX-12345 completed successfully';
      final result = AppLogger.maskPii(input);

      expect(result, equals(input));
    });

    test('handles empty string', () {
      expect(AppLogger.maskPii(''), equals(''));
    });
  });

  group('AppLogger API surface', () {
    // These tests verify the API compiles and doesn't throw.
    // In debug mode, developer.log is called — we can't easily intercept
    // it, but we can ensure no exceptions are thrown.

    test('info does not throw', () {
      expect(() => AppLogger.info('Test message'), returnsNormally);
    });

    test('info with tag does not throw', () {
      expect(
        () => AppLogger.info('Test message', tag: 'payments'),
        returnsNormally,
      );
    });

    test('warning does not throw', () {
      expect(
        () => AppLogger.warning('Test warning', tag: 'auth'),
        returnsNormally,
      );
    });

    test('warning with error does not throw', () {
      expect(
        () => AppLogger.warning(
          'Something failed',
          tag: 'webhook',
          error: Exception('test'),
        ),
        returnsNormally,
      );
    });

    test('error does not throw', () {
      expect(
        () => AppLogger.error('Critical failure', tag: 'escrow'),
        returnsNormally,
      );
    });

    test('error with error and stackTrace does not throw', () {
      final stackTrace = StackTrace.current;
      expect(
        () => AppLogger.error(
          'Critical failure',
          tag: 'escrow',
          error: Exception('test'),
          stackTrace: stackTrace,
        ),
        returnsNormally,
      );
    });
  });
}
