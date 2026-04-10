/// Typed exceptions emitted by [ImageUploadRepository] implementations.
///
/// The presentation layer branches on concrete type to decide:
/// - whether to mark [isRetryable] true or false
/// - which l10n error key to show
/// - whether to capture to Sentry (infra) or not (user error)
library;

/// Base for all image upload errors. Carries the l10n error key directly
/// so presentation code never hardcodes l10n strings.
sealed class ImageUploadException implements Exception {
  const ImageUploadException(this.errorKey);

  /// l10n key. See `assets/l10n/{en-US,nl-NL}.json` → `sell.uploadError*`.
  final String errorKey;

  /// Whether the user should see a retry affordance.
  bool get isRetryable;

  /// Whether to capture to Sentry. Infra errors → true; user errors → false.
  bool get shouldReport;

  @override
  String toString() => '$runtimeType(errorKey: $errorKey)';
}

/// Network failure, timeout, or DNS error. Retryable.
class ImageUploadNetworkException extends ImageUploadException {
  const ImageUploadNetworkException({this.cause})
    : super('sell.uploadErrorNetwork');

  final Object? cause;

  @override
  bool get isRetryable => true;

  @override
  bool get shouldReport => true;
}

/// HTTP 5xx from Storage or Edge Function, or HTTP 429 rate limit. Retryable.
class ImageUploadServerException extends ImageUploadException {
  const ImageUploadServerException({required this.statusCode, this.details})
    : super('sell.uploadErrorNetwork');

  final int statusCode;
  final Object? details;

  @override
  bool get isRetryable => true;

  @override
  bool get shouldReport => true;
}

/// HTTP 401/403 — auth token missing or path mismatch. Not retryable.
class ImageUploadAuthException extends ImageUploadException {
  const ImageUploadAuthException({this.statusCode})
    : super('sell.uploadErrorAuth');

  final int? statusCode;

  @override
  bool get isRetryable => false;

  @override
  bool get shouldReport => true;
}

/// HTTP 422 — Cloudmersive scan flagged the file. Terminal user error.
class ImageUploadBlockedException extends ImageUploadException {
  const ImageUploadBlockedException() : super('sell.uploadErrorBlocked');

  @override
  bool get isRetryable => false;

  @override
  bool get shouldReport => false;
}

/// HTTP 413 — file exceeded the 15 MiB server-side limit. Terminal.
class ImageUploadTooLargeException extends ImageUploadException {
  const ImageUploadTooLargeException() : super('sell.uploadErrorTooLarge');

  @override
  bool get isRetryable => false;

  @override
  bool get shouldReport => false;
}

/// HTTP 400 — malformed payload / unsupported format after server check.
class ImageUploadInvalidException extends ImageUploadException {
  const ImageUploadInvalidException() : super('sell.uploadErrorGeneric');

  @override
  bool get isRetryable => false;

  @override
  bool get shouldReport => false;
}

/// The user cancelled the upload (photo removed, navigated away, etc.).
///
/// Not shown to users — the queue silently drops these.
class ImageUploadCancelledException extends ImageUploadException {
  const ImageUploadCancelledException() : super('sell.uploadErrorGeneric');

  @override
  bool get isRetryable => false;

  @override
  bool get shouldReport => false;
}
