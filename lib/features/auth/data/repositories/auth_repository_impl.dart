import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';
import 'package:deelmarkt/features/auth/domain/repositories/auth_repository.dart';
import 'package:deelmarkt/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:deelmarkt/features/auth/data/biometric_service.dart';

/// Supabase-backed [AuthRepository] implementation.
///
/// Catches platform exceptions and translates them to domain
/// [AppException] subtypes with l10n error keys.
///
/// Login methods return [AuthResult] (sealed class) instead of throwing,
/// enabling exhaustive `switch` in the ViewModel.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._datasource, {required this.biometricService});
  final AuthRemoteDatasource _datasource;
  final BiometricService biometricService;

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
      throw _mapAuthError(e);
    } catch (e) {
      throw _mapGenericError(e);
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
      throw _mapAuthError(e);
    } catch (e) {
      throw _mapGenericError(e);
    }
  }

  @override
  Future<void> resendEmailOtp({required String email}) async {
    try {
      await _datasource.resendEmailOtp(email: email);
    } on sb.AuthException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      throw _mapGenericError(e);
    }
  }

  @override
  Future<void> sendPhoneOtp({required String phone}) async {
    try {
      await _datasource.sendPhoneOtp(phone: phone);
    } on sb.AuthException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      throw _mapGenericError(e);
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
      throw _mapAuthError(e);
    } catch (e) {
      throw _mapGenericError(e);
    }
  }

  // ── Login (P-16) ──

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
      return _mapLoginAuthError(e);
    } on Object catch (e) {
      return _mapLoginGenericError(e);
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

  AuthResult _mapLoginAuthError(sb.AuthException e) {
    final code = e.statusCode;
    if (code == '429') {
      return const AuthFailureRateLimited(retryAfter: Duration(minutes: 5));
    }
    if (code == '400') return const AuthFailureInvalidCredentials();

    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credential')) {
      return const AuthFailureInvalidCredentials();
    }
    if (msg.contains('rate')) {
      return const AuthFailureRateLimited(retryAfter: Duration(minutes: 5));
    }
    return AuthFailureUnknown(message: 'auth_error_status_$code');
  }

  // H-1 fix: Never pass raw e.toString() — may contain PII or internal URLs.
  AuthResult _mapLoginGenericError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('network') ||
        msg.contains('timeout')) {
      return const AuthFailureNetworkError(message: 'network_error');
    }
    return const AuthFailureUnknown(message: 'unknown_login_error');
  }

  AppException _mapAuthError(sb.AuthException e) {
    // Prefer status codes over message string matching for robustness.
    // Status codes are stable API contract; messages may change between
    // Supabase versions or be localised.
    final code = e.statusCode;

    // 429 — rate limited (check first, most actionable)
    if (code == '429') {
      return const AuthException('error.rate_limited');
    }
    // 422 — validation error (invalid OTP, expired token, etc.)
    if (code == '422') {
      final msg = e.message.toLowerCase();
      if (msg.contains('expired')) {
        return const AuthException('error.otp_expired');
      }
      return const AuthException('error.otp_invalid');
    }

    // Fall back to message matching for cases without distinct status codes
    final msg = e.message.toLowerCase();
    if (msg.contains('already registered') ||
        msg.contains('already been registered')) {
      return const AuthException('error.email_taken');
    }
    // C-4 fix: explicit parentheses for correct operator precedence
    if (msg.contains('invalid') &&
        (msg.contains('otp') || msg.contains('token'))) {
      return const AuthException('error.otp_invalid');
    }
    if (msg.contains('expired')) {
      return const AuthException('error.otp_expired');
    }
    if (msg.contains('rate')) {
      return const AuthException('error.rate_limited');
    }
    // H-7: sanitize — never pass raw Supabase message (may contain PII)
    return AuthException(
      'error.generic',
      debugMessage: 'auth_error_status_$code',
    );
  }

  // H-5: platform-agnostic network error handling (no dart:io)
  AppException _mapGenericError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('network') ||
        msg.contains('timeout')) {
      return const NetworkException();
    }
    return const AuthException('error.generic');
  }
}
