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
}
