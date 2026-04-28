import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/firebase_options.dart';

part 'firebase_service.g.dart';

/// Initialise Firebase once in `main()` before `runApp`.
///
/// Sets up Crashlytics error handlers for both Flutter and platform errors.
Future<void> initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Crashlytics is not supported on web.
  if (!kIsWeb) {
    // Crashlytics: capture all uncaught Flutter errors.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Crashlytics: capture platform-level errors (native crashes).
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Disable Crashlytics in debug mode to reduce noise.
    if (kDebugMode) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    }
  }

  // Remote Config: register defaults so perf_trace_sample_rate is usable
  // before the first server fetch. Best-effort fetchAndActivate ensures the
  // kill switch (ADR-027 §L1) takes effect on the current launch rather than
  // requiring a second cold start.
  await FirebaseRemoteConfig.instance.setDefaults(const {
    'perf_trace_sample_rate': '1.0',
  });
  try {
    await FirebaseRemoteConfig.instance.fetchAndActivate().timeout(
      const Duration(seconds: 5),
    );
  } on Exception catch (_) {
    // Fetch failed or timed out; defaults remain active.
  }

  // Performance Monitoring follows the same debug-disabled pattern as
  // Crashlytics — see ADR-027. NoopPerformanceTracer covers debug callers
  // through performanceTracerProvider, but disabling collection here also
  // suppresses auto-instrumented network/screen metrics in debug builds.
  // perf_trace_sample_rate = 0.0 disables collection without redeploy.
  final sampleRate = FirebaseRemoteConfig.instance.getDouble(
    'perf_trace_sample_rate',
  );
  await FirebasePerformance.instance.setPerformanceCollectionEnabled(
    !kDebugMode && sampleRate > 0.0,
  );
}

/// Global [FirebaseAnalytics] instance — overridable in tests.
@Riverpod(keepAlive: true)
FirebaseAnalytics firebaseAnalytics(FirebaseAnalyticsRef ref) {
  return FirebaseAnalytics.instance;
}

/// Global [FirebaseCrashlytics] instance.
@Riverpod(keepAlive: true)
FirebaseCrashlytics firebaseCrashlytics(FirebaseCrashlyticsRef ref) {
  return FirebaseCrashlytics.instance;
}

/// Global [FirebaseMessaging] instance (FCM).
@Riverpod(keepAlive: true)
FirebaseMessaging firebaseMessaging(FirebaseMessagingRef ref) {
  return FirebaseMessaging.instance;
}

/// Global [FirebaseRemoteConfig] instance.
@Riverpod(keepAlive: true)
FirebaseRemoteConfig firebaseRemoteConfig(FirebaseRemoteConfigRef ref) {
  return FirebaseRemoteConfig.instance;
}

/// Global [FirebasePerformance] instance.
@Riverpod(keepAlive: true)
FirebasePerformance firebasePerformance(FirebasePerformanceRef ref) {
  return FirebasePerformance.instance;
}
