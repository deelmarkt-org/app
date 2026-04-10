import 'package:deelmarkt/core/exceptions/app_exception.dart';

/// Maps `image-upload-process` Edge Function HTTP errors to typed
/// [AppException] subclasses with stable l10n keys.
///
/// Extracted from [ImageUploadService] so the service file stays under
/// the 200-line repository limit (CLAUDE.md §2.1) and so callers
/// (and tests) can reason about the mapping in one place.
///
/// | HTTP | Exception           | l10n key                                |
/// | ---- | ------------------- | --------------------------------------- |
/// | 401  | AuthException       | `error.auth.unauthenticated`            |
/// | 403  | AuthException       | `error.image.ownership_mismatch`        |
/// | 404  | NetworkException    | (storage object vanished — transport)   |
/// | 413  | ValidationException | `error.image.too_large`                 |
/// | 422  | ValidationException | `error.image.blocked`                   |
/// | 429  | ValidationException | `error.image.rate_limited`              |
/// | 502  | NetworkException    | (Cloudinary outage)                     |
/// | 503  | NetworkException    | (Cloudmersive scan outage)              |
/// | 5xx  | NetworkException    | (generic transport)                     |
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
        final retryAfter =
            body is Map<String, dynamic> ? body['retry_after_seconds'] : null;
        return ValidationException(
          'error.image.rate_limited',
          debugMessage: 'image-upload-process 429, retry_after=$retryAfter',
        );
      case 404:
      case 502:
        return NetworkException(
          debugMessage: 'image-upload-process returned $status',
        );
      case 503:
        return const NetworkException(
          debugMessage: 'error.image.scan_unavailable',
        );
      default:
        return NetworkException(
          debugMessage: 'image-upload-process returned unexpected $status',
        );
    }
  }
}
