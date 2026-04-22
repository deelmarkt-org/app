import 'package:deelmarkt/core/exceptions/app_exception.dart';

/// Maps `image-upload-process` Edge Function HTTP errors to typed
/// [AppException] subclasses with stable l10n keys.
///
/// Extracted from [ImageUploadService] so the service file stays under
/// the 200-line repository limit (CLAUDE.md §2.1) and so callers
/// (and tests) can reason about the mapping in one place.
///
/// The caller should invoke this from the `on FunctionException catch`
/// branch of its `functions.invoke()` call — supabase_flutter throws
/// `FunctionException` on any non-2xx response (it never returns a
/// `FunctionResponse` with `status >= 300`), so this switch runs only
/// off the exception's `status` + `details` fields.
///
/// | HTTP | Exception           | l10n key                                |
/// | ---- | ------------------- | --------------------------------------- |
/// | 401  | AuthException       | `error.auth.unauthenticated`            |
/// | 403  | AuthException       | `error.image.ownership_mismatch`        |
/// | 404  | NetworkException    | `error.image.not_found`                 |
/// | 413  | ValidationException | `error.image.too_large`                 |
/// | 422  | ValidationException | `error.image.blocked`                   |
/// | 429  | ValidationException | `error.image.rate_limited`              |
/// | 500  | NetworkException    | `error.image.upload_failed`             |
/// | 502  | NetworkException    | `error.image.upload_failed`             |
/// | 503  | NetworkException    | `error.image.scan_unavailable`          |
/// | 5xx  | NetworkException    | `error.network`                         |
abstract final class ImageUploadErrorMapper {
  /// Maps an EF HTTP error to the closest existing [AppException]
  /// subtype with a stable l10n key. The [body] is the parsed JSON
  /// payload (may be null) — used to surface threat names in the
  /// debug message for 422 responses without exposing them to users.
  static AppException map(int status, Object? body) {
    switch (status) {
      case 401:
        return const AuthException(
          'error.auth.unauthenticated',
          debugMessage: 'image-upload-process returned 401',
        );
      case 403:
        return const AuthException(
          'error.image.ownership_mismatch',
          debugMessage: 'image-upload-process returned 403',
        );
      case 404:
        return const NetworkException(
          messageKey: 'error.image.not_found',
          debugMessage: 'image-upload-process returned 404',
        );
      case 413:
        return const ValidationException(
          'error.image.too_large',
          debugMessage: 'image-upload-process returned 413',
        );
      case 422:
        // Server includes the threat name in the error field — carry it
        // into debugMessage only (never shown to users).
        final threat = body is Map<String, dynamic> ? body['error'] : null;
        return ValidationException(
          'error.image.blocked',
          debugMessage: 'Image blocked: $threat',
        );
      case 429:
        final retryAfter = _parseRetryAfter(body);
        return ValidationException(
          'error.image.rate_limited',
          debugMessage:
              'image-upload-process 429, retry_after=${retryAfter?.inSeconds}',
          retryAfter: retryAfter,
        );
      case 500:
      case 502:
        return NetworkException(
          messageKey: 'error.image.upload_failed',
          debugMessage: 'image-upload-process returned $status',
        );
      case 503:
        return const NetworkException(
          messageKey: 'error.image.scan_unavailable',
          debugMessage:
              'image-upload-process returned 503 (Cloudmersive outage)',
        );
      default:
        return NetworkException(
          debugMessage: 'image-upload-process returned unexpected $status',
        );
    }
  }

  /// Defensively parses `retry_after_seconds` from a 429 response body.
  ///
  /// Returns null for any malformed input — non-map bodies, missing field,
  /// non-numeric values, negatives, or zero. The presentation layer always
  /// applies a local safety floor, so null simply means "no server hint".
  static Duration? _parseRetryAfter(Object? body) {
    if (body is! Map<String, dynamic>) return null;
    final raw = body['retry_after_seconds'];
    final seconds = switch (raw) {
      final int v => v,
      final double v => v.toInt(),
      final String v => int.tryParse(v),
      _ => null,
    };
    if (seconds == null || seconds <= 0) return null;
    return Duration(seconds: seconds);
  }
}
