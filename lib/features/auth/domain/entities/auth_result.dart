import 'package:equatable/equatable.dart';

/// Auth outcome — exhaustive via Dart 3 sealed class.
///
/// Used by the presentation layer's `switch` for error handling.
/// Extends [Equatable] for Riverpod state diffing.
///
/// Reference: docs/epics/E02-user-auth-kyc.md
sealed class AuthResult extends Equatable {
  const AuthResult();
}

/// Login succeeded.
final class AuthSuccess extends AuthResult {
  const AuthSuccess({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Email or password incorrect.
final class AuthFailureInvalidCredentials extends AuthResult {
  const AuthFailureInvalidCredentials();

  @override
  List<Object?> get props => [];
}

/// Network unreachable or request timed out.
final class AuthFailureNetworkError extends AuthResult {
  const AuthFailureNetworkError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Too many login attempts — Supabase rate limiter.
final class AuthFailureRateLimited extends AuthResult {
  const AuthFailureRateLimited({required this.retryAfter});

  final Duration retryAfter;

  @override
  List<Object?> get props => [retryAfter];
}

/// Biometric hardware not available or not enrolled.
final class AuthFailureBiometricUnavailable extends AuthResult {
  const AuthFailureBiometricUnavailable();

  @override
  List<Object?> get props => [];
}

/// Biometric prompt failed (user cancelled or not recognised).
final class AuthFailureBiometricFailed extends AuthResult {
  const AuthFailureBiometricFailed();

  @override
  List<Object?> get props => [];
}

/// Biometric succeeded but refresh token has expired (>30 days).
/// User must re-authenticate with email.
final class AuthFailureSessionExpired extends AuthResult {
  const AuthFailureSessionExpired();

  @override
  List<Object?> get props => [];
}

/// Catch-all for unexpected errors.
final class AuthFailureUnknown extends AuthResult {
  const AuthFailureUnknown({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// User dismissed the OAuth consent sheet before completing sign-in.
final class AuthFailureOAuthCancelled extends AuthResult {
  const AuthFailureOAuthCancelled();

  @override
  List<Object?> get props => [];
}

/// OAuth provider not configured or temporarily unavailable.
final class AuthFailureOAuthUnavailable extends AuthResult {
  const AuthFailureOAuthUnavailable();

  @override
  List<Object?> get props => [];
}

/// Domain-level biometric type — avoids importing `local_auth` in domain layer.
enum BiometricMethod { face, fingerprint }

/// Domain-level OAuth provider — avoids importing Supabase in domain layer.
enum OAuthProvider { google, apple }
