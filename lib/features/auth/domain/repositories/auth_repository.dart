import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';

/// Abstract auth repository — domain layer, no Supabase imports.
///
/// Data layer implements this interface and translates platform
/// exceptions into domain [AppException] subtypes.
abstract interface class AuthRepository {
  /// Register a new user with email + password.
  ///
  /// [termsAcceptedAt] and [privacyAcceptedAt] are stored in
  /// Supabase auth.users.raw_user_meta_data for GDPR audit trail.
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required DateTime termsAcceptedAt,
    required DateTime privacyAcceptedAt,
  });

  /// Verify the email OTP code sent during registration.
  Future<void> verifyEmailOtp({required String email, required String token});

  /// Resend the email OTP for an existing registration.
  Future<void> resendEmailOtp({required String email});

  /// Send an OTP code to [phone] via SMS.
  Future<void> sendPhoneOtp({required String phone});

  /// Verify the phone OTP code.
  Future<void> verifyPhoneOtp({required String phone, required String token});

  // ── Login (P-16) ──

  /// Authenticate with email + password via Supabase Auth.
  Future<AuthResult> loginWithEmail({
    required String email,
    required String password,
  });

  /// Authenticate via biometric (Face ID / fingerprint) + session refresh.
  /// [localizedReason] is displayed in the OS biometric prompt — must be l10n'd.
  Future<AuthResult> loginWithBiometric({required String localizedReason});

  /// Whether biometric hardware is available and enrolled.
  Future<bool> get isBiometricAvailable;

  /// Which biometric method is available (face or fingerprint), or null.
  Future<BiometricMethod?> get availableBiometricMethod;

  /// Initiate iDIN bank verification flow.
  ///
  /// Returns the redirect URL for the iDIN bank selection page.
  /// The URL MUST be validated against an allowlist before opening.
  Future<String> initiateIdinVerification();
}
