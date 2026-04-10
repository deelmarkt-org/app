/// Base exception hierarchy for domain-level error handling.
///
/// Uses `sealed` class (Dart 3.x) so ViewModels can exhaustively
/// `switch` on exception subtypes. [messageKey] is always an l10n key
/// — never a raw server error string.
sealed class AppException implements Exception {
  const AppException(this.messageKey, {this.debugMessage});

  /// Localisation key for the user-facing error message.
  /// UI calls `.tr()` on this value — never display [debugMessage] to users.
  final String messageKey;

  /// Internal debug information for structured logging.
  /// Never contains PII (email, phone, names) — only event types and IDs.
  final String? debugMessage;

  @override
  String toString() => '$runtimeType($messageKey)';
}

/// Authentication-related failures (invalid credentials, OTP errors, etc.).
final class AuthException extends AppException {
  const AuthException(super.messageKey, {super.debugMessage});
}

/// Network connectivity failures (no internet, timeouts, upstream 5xx).
///
/// [messageKey] defaults to `error.network` to preserve the no-arg
/// construction used across the codebase. Callers that want to surface
/// a more specific transient failure (e.g. `error.image.scan_unavailable`
/// for a Cloudmersive outage) can pass a dedicated key — the UI still
/// treats it as a generic transient/network-class failure so retry
/// buttons keep their current affordance, but the user sees the right
/// cause line.
final class NetworkException extends AppException {
  const NetworkException({
    String messageKey = 'error.network',
    super.debugMessage,
  }) : super(messageKey);
}

/// Input validation failures.
final class ValidationException extends AppException {
  const ValidationException(super.messageKey, {super.debugMessage});
}
