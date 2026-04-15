import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';

/// Shared error-mapping logic for [AuthRepositoryImpl].
///
/// Extracted to keep the repository implementation under the 200-line limit
/// per CLAUDE.md §2.1.
mixin AuthErrorMapper {
  /// Default retry duration when Supabase doesn't expose Retry-After.
  static const defaultRateLimitRetry = Duration(minutes: 5);

  // ── Login error mappers (return AuthResult) ──────────────────────────

  /// Maps OAuth-specific auth errors (provider disabled → unavailable, rest → login).
  ///
  /// Prefers Supabase's stable error [code] (e.g. `validation_failed`,
  /// `provider_disabled`, 422 with provider body) over substring matching on
  /// [message], which is localisable and may change between SDK versions.
  AuthResult mapOAuthAuthError(sb.AuthException e) {
    final code = e.code?.toLowerCase();
    if (code == 'provider_disabled' ||
        code == 'oauth_provider_not_supported' ||
        code == 'validation_failed' ||
        code == 'unsupported_provider') {
      return const AuthFailureOAuthUnavailable();
    }
    // Supabase returns 422 with body `error_code: validation_failed` when a
    // provider isn't configured. Fall back to message match for older SDKs.
    final msg = e.message.toLowerCase();
    if (msg.contains('provider') &&
        (msg.contains('disabled') ||
            msg.contains('not configured') ||
            msg.contains('not supported'))) {
      return const AuthFailureOAuthUnavailable();
    }
    return mapLoginAuthError(e);
  }

  AuthResult mapLoginAuthError(sb.AuthException e) {
    final code = e.statusCode;
    if (code == '429') {
      return const AuthFailureRateLimited(retryAfter: defaultRateLimitRetry);
    }
    if (code == '400') return const AuthFailureInvalidCredentials();

    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credential')) {
      return const AuthFailureInvalidCredentials();
    }
    if (msg.contains('rate')) {
      return const AuthFailureRateLimited(retryAfter: defaultRateLimitRetry);
    }
    return AuthFailureUnknown(message: 'auth_error_status_$code');
  }

  /// H-1 fix: Never pass raw e.toString() — may contain PII or internal URLs.
  AuthResult mapLoginGenericError(Object e) {
    if (_isNetworkError(e)) {
      return const AuthFailureNetworkError(message: 'network_error');
    }
    return const AuthFailureUnknown(message: 'unknown_login_error');
  }

  // ── Registration error mappers (throw AppException) ──────────────────

  AppException mapAuthError(sb.AuthException e) {
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

  /// H-5: platform-agnostic network error handling (no dart:io).
  AppException mapGenericError(Object e) {
    if (_isNetworkError(e)) {
      return const NetworkException();
    }
    return const AuthException('error.generic');
  }

  /// Check exception type name first (stable across locales), then fall back
  /// to message matching. Avoids `dart:io` import for Flutter web compatibility.
  bool _isNetworkError(Object e) {
    final typeName = e.runtimeType.toString();
    if (typeName == 'SocketException' ||
        typeName == 'HttpException' ||
        typeName == 'TimeoutException' ||
        typeName == 'ClientException') {
      return true;
    }
    final msg = e.toString().toLowerCase();
    return msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('network') ||
        msg.contains('timeout');
  }
}
