import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/auth/domain/repositories/auth_repository.dart';
import 'package:deelmarkt/features/auth/data/datasources/auth_remote_datasource.dart';

/// Supabase-backed [AuthRepository] implementation.
///
/// Catches platform exceptions and translates them to domain
/// [AppException] subtypes with l10n error keys.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._datasource);
  final AuthRemoteDatasource _datasource;

  @override
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required DateTime termsAcceptedAt,
    required DateTime privacyAcceptedAt,
  }) async {
    try {
      await _datasource.signUpWithEmail(
        email: email,
        password: password,
        metadata: {
          'terms_accepted_at': termsAcceptedAt.toIso8601String(),
          'privacy_accepted_at': privacyAcceptedAt.toIso8601String(),
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

  AppException _mapAuthError(sb.AuthException e) {
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
    if (e.statusCode == '429' || msg.contains('rate')) {
      return const AuthException('error.rate_limited');
    }
    // H-7: sanitize — never pass raw Supabase message (may contain PII)
    return AuthException(
      'error.generic',
      debugMessage: 'auth_error_status_${e.statusCode}',
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
