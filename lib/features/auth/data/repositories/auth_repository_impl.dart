import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';
import 'package:deelmarkt/features/auth/domain/repositories/auth_repository.dart';
import 'package:deelmarkt/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:deelmarkt/features/auth/data/biometric_service.dart';
import 'package:deelmarkt/features/auth/data/repositories/auth_error_mapper.dart';
import 'package:deelmarkt/features/auth/data/repositories/oauth_login_orchestrator.dart';

/// Supabase-backed [AuthRepository]. Translates platform exceptions to domain
/// [AuthResult] / [AppException] types. Error mapping lives in [AuthErrorMapper];
/// OAuth flow orchestration in [OAuthLoginOrchestrator].
class AuthRepositoryImpl with AuthErrorMapper implements AuthRepository {
  AuthRepositoryImpl(
    this._datasource, {
    required this.biometricService,
    Duration oauthTimeout = const Duration(seconds: 60),
  }) : _oauth = OAuthLoginOrchestrator(_datasource, timeout: oauthTimeout);
  final AuthRemoteDatasource _datasource;
  final BiometricService biometricService;
  final OAuthLoginOrchestrator _oauth;

  @override
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required DateTime termsAcceptedAt,
    required DateTime privacyAcceptedAt,
  }) async {
    try {
      // Use UTC timestamps generated at call time for GDPR audit trail.
      // Client-passed timestamps are unreliable (clock skew, timezone).
      // The authoritative record is Supabase auth.users.created_at.
      final serverNow = DateTime.now().toUtc().toIso8601String();
      await _datasource.signUpWithEmail(
        email: email,
        password: password,
        metadata: {
          'terms_accepted_at': serverNow,
          'privacy_accepted_at': serverNow,
        },
      );
    } on sb.AuthException catch (e) {
      throw mapAuthError(e);
    } catch (e) {
      throw mapGenericError(e);
    }
  }

  @override
  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    try {
      await _datasource.verifyEmailOtp(email: email, token: token);
    } on sb.AuthException catch (e) {
      throw mapAuthError(e);
    } catch (e) {
      throw mapGenericError(e);
    }
  }

  @override
  Future<void> resendEmailOtp({required String email}) async {
    try {
      await _datasource.resendEmailOtp(email: email);
    } on sb.AuthException catch (e) {
      throw mapAuthError(e);
    } catch (e) {
      throw mapGenericError(e);
    }
  }

  @override
  Future<void> sendPhoneOtp({required String phone}) async {
    try {
      await _datasource.sendPhoneOtp(phone: phone);
    } on sb.AuthException catch (e) {
      throw mapAuthError(e);
    } catch (e) {
      throw mapGenericError(e);
    }
  }

  @override
  Future<void> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    try {
      await _datasource.verifyPhoneOtp(phone: phone, token: token);
    } on sb.AuthException catch (e) {
      throw mapAuthError(e);
    } catch (e) {
      throw mapGenericError(e);
    }
  }

  @override
  Future<String> initiateIdinVerification() async {
    try {
      final response = await _datasource.initiateIdin();
      final data = response.data as Map<String, dynamic>?;
      final url = data?['redirect_url'];
      if (url is! String || url.isEmpty) {
        throw const NetworkException(
          debugMessage: 'iDIN EF returned no redirect_url',
        );
      }
      return url;
    } on sb.FunctionException catch (e) {
      if (e.status == 409) {
        throw const sb.AuthException('A verification is already in progress.');
      }
      throw mapGenericError(e);
    } on sb.AuthException catch (e) {
      throw mapAuthError(e);
    } catch (e) {
      throw mapGenericError(e);
    }
  }

  @override
  Future<AuthResult> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _datasource.signInWithPassword(
        email: email,
        password: password,
      );
      final userId = response.user?.id;
      if (userId == null) {
        return const AuthFailureUnknown(message: 'No user returned');
      }
      return AuthSuccess(userId: userId);
    } on sb.AuthException catch (e) {
      return mapLoginAuthError(e);
    } on Object catch (e) {
      return mapLoginGenericError(e);
    }
  }

  @override
  Future<AuthResult> loginWithBiometric({
    required String localizedReason,
  }) async {
    final available = await biometricService.isAvailable;
    if (!available) return const AuthFailureBiometricUnavailable();

    final session = _datasource.currentSession;
    if (session == null) return const AuthFailureBiometricUnavailable();

    final authenticated = await biometricService.authenticate(
      localizedReason: localizedReason,
    );
    if (!authenticated) return const AuthFailureBiometricFailed();

    try {
      final response = await _datasource.refreshSession();
      final userId = response.user?.id;
      if (userId == null) return const AuthFailureSessionExpired();
      return AuthSuccess(userId: userId);
    } on sb.AuthException {
      return const AuthFailureSessionExpired();
    } on Object {
      return const AuthFailureSessionExpired();
    }
  }

  @override
  Future<bool> get isBiometricAvailable async {
    final available = await biometricService.isAvailable;
    if (!available) return false;
    // Biometric login requires an existing session to refresh
    return _datasource.currentSession != null;
  }

  @override
  Future<BiometricMethod?> get availableBiometricMethod =>
      biometricService.availableMethod;

  @override
  Future<AuthResult> loginWithOAuth(OAuthProvider provider) =>
      _oauth.loginWithOAuth(provider);
}
