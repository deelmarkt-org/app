import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:deelmarkt/core/services/env.dart';

/// Initialise Sentry in `main()` before `runApp`.
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
      ..tracesSampleRate = 0.2
      ..attachScreenshot = true
      ..sendDefaultPii = false;
  });
}

/// Capture an exception with optional stack trace in Sentry.
Future<void> sentryCaptureException(
  dynamic exception, {
  StackTrace? stackTrace,
}) async {
  await Sentry.captureException(exception, stackTrace: stackTrace);
}

/// Capture a plain message in Sentry.
Future<void> sentryCaptureMessage(String message) async {
  await Sentry.captureMessage(message);
}
