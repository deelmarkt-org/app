import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps [SupabaseClient.auth] calls for registration and OTP verification.
///
/// This class is the only layer that knows about Supabase. The repository
/// catches exceptions from here and translates them to domain exceptions.
class AuthRemoteDatasource {
  const AuthRemoteDatasource(this._client);
  final SupabaseClient _client;

  /// Register with email + password. Consent timestamps are stored
  /// in `auth.users.raw_user_meta_data` for GDPR audit trail.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: metadata,
    );
  }

  /// Resend the email OTP for an existing registration.
  Future<void> resendEmailOtp({required String email}) async {
    await _client.auth.resend(type: OtpType.signup, email: email);
  }

  /// Verify the email OTP token sent during registration.
  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) {
    return _client.auth.verifyOTP(
      type: OtpType.email,
      email: email,
      token: token,
    );
  }

  /// Send an SMS OTP to [phone] (E.164 format).
  Future<void> sendPhoneOtp({required String phone}) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  /// Verify the phone SMS OTP.
  Future<AuthResponse> verifyPhoneOtp({
    required String phone,
    required String token,
  }) {
    return _client.auth.verifyOTP(
      type: OtpType.sms,
      phone: phone,
      token: token,
    );
  }

  // ── Login (P-16) ──

  /// Sign in with email + password.
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Refresh the current session (for biometric re-auth).
  Future<AuthResponse> refreshSession() {
    return _client.auth.refreshSession();
  }

  /// Returns the current session or null.
  Session? get currentSession => _client.auth.currentSession;

  /// Initiates iDIN verification via the `initiate-idin` Edge Function.
  ///
  /// Returns the raw [FunctionResponse]. URL allowlist validation is enforced
  /// by [InitiateIdinVerificationUseCase] in the domain layer, not here.
  Future<FunctionResponse> initiateIdin() {
    return _client.functions.invoke('initiate-idin');
  }
}
