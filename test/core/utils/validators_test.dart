import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('returns null for valid emails', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('a.b+c@test.co.uk'), isNull);
      expect(Validators.email('test@domain.nl'), isNull);
    });

    test('returns required key for null/empty', () {
      expect(Validators.email(null), 'validation.email_required');
      expect(Validators.email(''), 'validation.email_required');
      expect(Validators.email('   '), 'validation.email_required');
    });

    test('returns invalid key for bad format', () {
      expect(Validators.email('nope'), 'validation.email_invalid');
      expect(Validators.email('no@'), 'validation.email_invalid');
      expect(Validators.email('@test.com'), 'validation.email_invalid');
    });
  });

  group('Validators.password', () {
    test('returns null for valid passwords', () {
      expect(Validators.password('Abcdef1g'), isNull);
      expect(Validators.password('Str0ngPa\$\$'), isNull);
    });

    test('returns required key for null/empty', () {
      expect(Validators.password(null), 'validation.password_required');
      expect(Validators.password(''), 'validation.password_required');
    });

    test('returns too_short for < 8 chars', () {
      expect(Validators.password('Ab1'), 'validation.password_too_short');
      expect(Validators.password('Short1A'), 'validation.password_too_short');
    });

    test('returns needs_uppercase when missing', () {
      expect(
        Validators.password('abcdefg1'),
        'validation.password_needs_uppercase',
      );
    });

    test('returns needs_lowercase when missing', () {
      expect(
        Validators.password('ABCDEFG1'),
        'validation.password_needs_lowercase',
      );
    });

    test('returns needs_digit when missing', () {
      expect(
        Validators.password('Abcdefgh'),
        'validation.password_needs_digit',
      );
    });
  });

  group('Validators.dutchPhone', () {
    test('returns null for valid Dutch phones', () {
      expect(Validators.dutchPhone('+31612345678'), isNull);
      expect(Validators.dutchPhone('0612345678'), isNull);
      expect(Validators.dutchPhone('+31 6 12345678'), isNull);
      expect(Validators.dutchPhone('06 12345678'), isNull);
    });

    test('returns required key for null/empty', () {
      expect(Validators.dutchPhone(null), 'validation.phone_required');
      expect(Validators.dutchPhone(''), 'validation.phone_required');
    });

    test('returns invalid key for bad format', () {
      expect(Validators.dutchPhone('+44123456789'), 'validation.phone_invalid');
      expect(Validators.dutchPhone('123'), 'validation.phone_invalid');
      expect(
        Validators.dutchPhone('+310612345678'),
        'validation.phone_invalid',
      );
    });
  });

  group('Validators.otp', () {
    test('returns null for valid 6-digit OTP', () {
      expect(Validators.otp('123456'), isNull);
      expect(Validators.otp('000000'), isNull);
    });

    test('returns required key for null/empty', () {
      expect(Validators.otp(null), 'validation.otp_required');
      expect(Validators.otp(''), 'validation.otp_required');
    });

    test('returns invalid key for wrong format', () {
      expect(Validators.otp('12345'), 'validation.otp_invalid');
      expect(Validators.otp('1234567'), 'validation.otp_invalid');
      expect(Validators.otp('abcdef'), 'validation.otp_invalid');
    });
  });

  group('Validators.normalizePhone', () {
    test('normalizes 06 format to E.164', () {
      expect(Validators.normalizePhone('0612345678'), '+31612345678');
    });

    test('normalizes 0031 format', () {
      expect(Validators.normalizePhone('0031612345678'), '+31612345678');
    });

    test('preserves +31 format', () {
      expect(Validators.normalizePhone('+31612345678'), '+31612345678');
    });

    test('strips whitespace and dashes', () {
      expect(Validators.normalizePhone('+31 6 123 456 78'), '+31612345678');
      expect(Validators.normalizePhone('06-12345678'), '+31612345678');
    });
  });

  group('Validators.passwordStrength', () {
    test('returns weak for short passwords', () {
      expect(Validators.passwordStrength('short'), PasswordStrength.weak);
      expect(Validators.passwordStrength('Ab1'), PasswordStrength.weak);
    });

    test('returns fair for 8+ chars with 2 criteria', () {
      expect(Validators.passwordStrength('Abcdefgh'), PasswordStrength.fair);
      expect(Validators.passwordStrength('abcdefg1'), PasswordStrength.fair);
    });

    test('returns strong for 10+ chars with 3 criteria', () {
      expect(
        Validators.passwordStrength('Abcdefgh12'),
        PasswordStrength.strong,
      );
    });

    test('returns veryStrong for 12+ chars with 4 criteria', () {
      expect(
        Validators.passwordStrength('Abcdefgh12!\$'),
        PasswordStrength.veryStrong,
      );
    });
  });
}
