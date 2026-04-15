import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/auth/data/datasources/oauth_native_client.dart';

/// Wraps [SupabaseClient.auth] calls for registration, OTP, and OAuth sign-in.
///
/// This class is the only layer that knows about Supabase and OAuth packages.
/// The repository translates datasource exceptions into domain types.
/// Native OAuth logic lives in [OAuthNativeClient] to keep this file small.
class AuthRemoteDatasource {
  AuthRemoteDatasource(this._client, {OAuthNativeClient? oauth})
    : _oauth = oauth ?? OAuthNativeClient(_client);

  final SupabaseClient _client;
  final OAuthNativeClient _oauth;

  /// Register with email + password. Consent timestamps are stored in
  /// `auth.users.raw_user_meta_data` for GDPR audit trail.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  }) => _client.auth.signUp(email: email, password: password, data: metadata);

  Future<void> resendEmailOtp({required String email}) =>
      _client.auth.resend(type: OtpType.signup, email: email);

  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) => _client.auth.verifyOTP(type: OtpType.email, email: email, token: token);

  Future<void> sendPhoneOtp({required String phone}) =>
      _client.auth.signInWithOtp(phone: phone);

  Future<AuthResponse> verifyPhoneOtp({
    required String phone,
    required String token,
  }) => _client.auth.verifyOTP(type: OtpType.sms, phone: phone, token: token);

  // ── Login (P-16) ──

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) => _client.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> refreshSession() => _client.auth.refreshSession();

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  Future<FunctionResponse> initiateIdin() =>
      _client.functions.invoke('initiate-idin');

  // ── Social Login (P-44) ──

  /// Stream of Supabase auth state changes — used by the repository to
  /// observe the `signedIn` event after a web OAuth redirect completes.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Google Sign-In — see [OAuthNativeClient.signInWithGoogle].
  Future<AuthResponse?> signInWithGoogle() => _oauth.signInWithGoogle();

  /// Apple Sign-In — see [OAuthNativeClient.signInWithApple].
  Future<AuthResponse?> signInWithApple() => _oauth.signInWithApple();
}
