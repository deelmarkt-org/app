import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/core/services/app_logger.dart';

const _logTag = 'photo-upload-queue';

/// Structured log of a single retry attempt boundary.
///
/// Dual-sink, matching the read-path pattern established in ADR-022
/// (`deel_card_image.dart` → `Sentry.captureMessage('image_load_failed')`):
/// - `AppLogger.warning` — `developer.log` in debug; Crashlytics non-fatal
///   in release (current [AppLogger] transport).
/// - `Sentry.addBreadcrumb` — attaches context to any subsequent captured
///   exception so on-call can see "retried N times with rateLimited=true
///   before failing" without searching log aggregates.
///
/// Fields are sanitized — only the photo UUID, attempt count, delay, and
/// exception runtime type are emitted. No URL, filename, or user id.
/// See ADR-026 §Observability.
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
  Sentry.addBreadcrumb(
    Breadcrumb(
      category: _logTag,
      type: 'default',
      level: SentryLevel.warning,
      message: 'upload_retry',
      data: {
        'photoId': photoId,
        'attempt': attempt,
        'maxAttempts': maxAttempts,
        'delayMs': delay.inMilliseconds,
        'rateLimited': isRateLimited,
        'cause': exception.runtimeType.toString(),
      },
    ),
  );
}

/// Distinct event from [logRetry] — fires when the global 60 s
/// `totalDeadline` would be exceeded by the next backoff. Lets on-call
/// tell a "retried and eventually gave up" from "retried to budget".
///
/// Captured as a Sentry message (not just a breadcrumb) so it surfaces on
/// the issues dashboard without requiring a co-occurring exception.
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
  Sentry.captureMessage(
    'upload_retry_budget_exhausted',
    level: SentryLevel.warning,
    withScope: (scope) {
      scope
        ..setTag('photoId', photoId)
        ..setTag('cause', exception.runtimeType.toString())
        ..setContexts('retry', {
          'attempt': attempt,
          'maxAttempts': maxAttempts,
          'totalDeadlineSec': totalDeadline.inSeconds,
        });
    },
  );
}
