import 'package:deelmarkt/features/transaction/domain/mollie_url_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MollieUrlValidator.isTrustedHost', () {
    test('returns true for exact Mollie domain', () {
      expect(
        MollieUrlValidator.isTrustedHost('https://www.mollie.com/checkout'),
        isTrue,
      );
    });

    test('returns true for bare mollie.com domain', () {
      expect(MollieUrlValidator.isTrustedHost('https://mollie.com/'), isTrue);
    });

    test('returns true for iDEAL bank redirect domain', () {
      expect(
        MollieUrlValidator.isTrustedHost('https://ideal.rabobank.nl/pay'),
        isTrue,
      );
    });

    test('returns true for all 14 trusted hosts', () {
      for (final host in MollieUrlValidator.trustedHosts) {
        expect(
          MollieUrlValidator.isTrustedHost('https://$host/path'),
          isTrue,
          reason: 'expected $host to be trusted',
        );
      }
    });

    test('returns false for untrusted host', () {
      expect(
        MollieUrlValidator.isTrustedHost('https://evil.com/phish'),
        isFalse,
      );
    });

    test('returns false for suffix-spoofed domain (attacker-mollie.com)', () {
      // Bare endsWith('mollie.com') would incorrectly allow this.
      expect(
        MollieUrlValidator.isTrustedHost('https://attacker-mollie.com/'),
        isFalse,
      );
    });

    test('returns true for legitimate subdomain (www.mollie.com)', () {
      expect(
        MollieUrlValidator.isTrustedHost('https://www.mollie.com/select-bank'),
        isTrue,
      );
    });

    test(
      'returns false for host that only contains a trusted suffix in path',
      () {
        expect(
          MollieUrlValidator.isTrustedHost('https://evil.com/mollie.com'),
          isFalse,
        );
      },
    );

    test('returns false for empty string', () {
      expect(MollieUrlValidator.isTrustedHost(''), isFalse);
    });

    test('returns false for malformed URL with no host', () {
      expect(MollieUrlValidator.isTrustedHost('not-a-url'), isFalse);
    });
  });

  group('MollieUrlValidator.isAllowed', () {
    test('allows https URL on trusted host', () {
      expect(
        MollieUrlValidator.isAllowed('https://www.mollie.com/select-issuer'),
        isTrue,
      );
    });

    test('blocks http URL even on trusted host', () {
      expect(
        MollieUrlValidator.isAllowed('http://www.mollie.com/checkout'),
        isFalse,
      );
    });

    test('blocks https URL on untrusted host', () {
      expect(
        MollieUrlValidator.isAllowed('https://attacker.com/steal'),
        isFalse,
      );
    });

    test('blocks empty string', () {
      expect(MollieUrlValidator.isAllowed(''), isFalse);
    });
  });
}
