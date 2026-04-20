import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/core/services/app_logger.dart';

const _logTag = 'photo-upload-queue';

/// Structured log of a single retry attempt boundary. Feeds Sentry
/// breadcrumbs and on-call dashboards. Fields are sanitized — only the
/// photo UUID, attempt count, delay, and exception runtime type are
/// emitted. No URL, filename, or user id. See ADR-026 §Observability.
void logRetry({
  required String photoId,
  required int attempt,
  required int maxAttempts,
  required Duration delay,
  required AppException exception,
}) {
  final isRateLimited =
      exception is ValidationException &&
      exception.messageKey == 'error.image.rate_limited';
  AppLogger.warning(
    'upload_retry '
    'photoId=$photoId attempt=$attempt/$maxAttempts '
    'delayMs=${delay.inMilliseconds} rateLimited=$isRateLimited '
    'cause=${exception.runtimeType}',
    tag: _logTag,
  );
}

/// Distinct event from [logRetry] — fires when the global 60 s
/// `totalDeadline` would be exceeded by the next backoff. Lets on-call
/// tell a "retried and eventually gave up" from "retried to budget".
void logRetryBudgetExhausted({
  required String photoId,
  required int attempt,
  required int maxAttempts,
  required Duration totalDeadline,
  required AppException exception,
}) {
  AppLogger.warning(
    'upload_retry_budget_exhausted '
    'photoId=$photoId attempt=$attempt/$maxAttempts '
    'totalDeadlineSec=${totalDeadline.inSeconds} '
    'cause=${exception.runtimeType}',
    tag: _logTag,
  );
}
