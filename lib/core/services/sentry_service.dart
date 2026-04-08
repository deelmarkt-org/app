import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:deelmarkt/core/services/env.dart';

/// Fraction of transactions sampled for performance monitoring.
const _tracesSampleRate = 0.2;

/// Initialise Sentry **before** other services so it captures init errors.
///
/// Sentry runs alongside Firebase Crashlytics:
/// - Crashlytics → crash aggregation + real-time alerting (Firebase console)
/// - Sentry → rich error context, breadcrumbs, release tracking, performance
///
/// Disabled in debug mode to avoid polluting Sentry with dev noise.
Future<void> initSentry() async {
  await SentryFlutter.init((options) {
    options
      ..dsn = kDebugMode ? '' : Env.sentryDsn
      ..environment = kDebugMode ? 'development' : 'production'
      ..tracesSampleRate = _tracesSampleRate
      ..attachScreenshot = false
      ..debug = kDebugMode
      ..sendDefaultPii = false;
  });
}

/// Capture an exception with optional stack trace in Sentry.
Future<SentryId> sentryCaptureException(
  dynamic exception, {
  StackTrace? stackTrace,
}) {
  return Sentry.captureException(exception, stackTrace: stackTrace);
}

/// Capture a plain message in Sentry.
Future<SentryId> sentryCaptureMessage(String message) {
  return Sentry.captureMessage(message);
}
