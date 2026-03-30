/// Pure-Dart validators for form fields.
///
/// All methods return `null` when valid, or an l10n error key when invalid.
/// No Flutter imports — usable in domain layer and tests.
abstract final class Validators {
  /// Email: non-empty + simplified RFC 5322 regex.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'validation.email_required';
    final pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$');
    if (!pattern.hasMatch(value.trim())) return 'validation.email_invalid';
    return null;
  }

  /// Password: min 8 chars, 1 uppercase, 1 lowercase, 1 digit.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'validation.password_required';
    if (value.length < 8) return 'validation.password_too_short';
    if (!value.contains(RegExp(r'[A-Z]')))
      return 'validation.password_needs_uppercase';
    if (!value.contains(RegExp(r'[a-z]')))
      return 'validation.password_needs_lowercase';
    if (!value.contains(RegExp(r'[0-9]')))
      return 'validation.password_needs_digit';
    return null;
  }

  /// Dutch mobile phone: +316XXXXXXXX or 06XXXXXXXX.
  static String? dutchPhone(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'validation.phone_required';
    final normalized = normalizePhone(value);
    // +31 followed by 9 digits (6XXXXXXXX)
    if (!RegExp(r'^\+31[1-9]\d{8}$').hasMatch(normalized)) {
      return 'validation.phone_invalid';
    }
    return null;
  }

  /// OTP: exactly 6 numeric digits.
  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) return 'validation.otp_required';
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim()))
      return 'validation.otp_invalid';
    return null;
  }

  /// Normalize phone to E.164 format: '0612345678' → '+31612345678'.
  static String normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[\s\-()]'), '');
    if (digits.startsWith('+31')) return digits;
    if (digits.startsWith('0031')) return '+31${digits.substring(4)}';
    if (digits.startsWith('0')) return '+31${digits.substring(1)}';
    return digits;
  }

  /// Password strength scoring for the visual indicator.
  static PasswordStrength passwordStrength(String value) {
    if (value.length < 8) return PasswordStrength.weak;

    var criteria = 0;
    if (value.contains(RegExp(r'[A-Z]'))) criteria++;
    if (value.contains(RegExp(r'[a-z]'))) criteria++;
    if (value.contains(RegExp(r'[0-9]'))) criteria++;
    if (value.contains(RegExp(r'[^A-Za-z0-9]'))) criteria++;

    if (value.length >= 12 && criteria >= 4) return PasswordStrength.veryStrong;
    if (value.length >= 10 && criteria >= 3) return PasswordStrength.strong;
    if (criteria >= 2) return PasswordStrength.fair;
    return PasswordStrength.weak;
  }
}

/// Password strength levels for the visual indicator.
enum PasswordStrength { weak, fair, strong, veryStrong }
