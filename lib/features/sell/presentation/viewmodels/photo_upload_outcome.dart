import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/sell/data/services/models/image_upload_response.dart';

/// Result of a single upload attempt as observed by the queue.
sealed class PhotoUploadOutcome {
  const PhotoUploadOutcome(this.id);
  final String id;
}

class PhotoUploadStarted extends PhotoUploadOutcome {
  const PhotoUploadStarted(super.id);
}

class PhotoUploadSucceeded extends PhotoUploadOutcome {
  const PhotoUploadSucceeded(super.id, this.response);
  final ImageUploadResponse response;
}

class PhotoUploadFailed extends PhotoUploadOutcome {
  const PhotoUploadFailed(super.id, this.exception);

  /// The [AppException] that caused the failure.
  ///
  /// [NetworkException] → retryable (transient infra error).
  /// [ValidationException] with key `error.image.rate_limited` → retryable.
  /// [AuthException] or other [ValidationException] → terminal (non-retryable).
  final AppException exception;

  /// Whether the UI should show a retry affordance for this failure.
  bool get isRetryable => switch (exception) {
    NetworkException() => true,
    ValidationException(messageKey: 'error.image.rate_limited') => true,
    _ => false,
  };
}
