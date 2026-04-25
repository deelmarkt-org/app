import 'package:deelmarkt/core/services/firebase_service.dart';
import 'package:deelmarkt/core/services/performance/firebase_performance_tracer.dart';
import 'package:deelmarkt/core/services/performance/noop_performance_tracer.dart';
import 'package:deelmarkt/core/services/performance/performance_tracer.dart';
import 'package:deelmarkt/core/services/performance/sentry_performance_tracer.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'performance_tracer_provider.g.dart';

/// Riverpod facade for the [PerformanceTracer] interface.
///
/// Selects the implementation at composition time:
///   - debug builds → [NoopPerformanceTracer]
///   - web release  → [SentryPerformanceTracer]
///   - mobile release → [FirebasePerformanceTracer]
///
/// Tests override this provider via `ProviderScope.overrides` with a
/// recording fake (see `test/_helpers/fake_performance_tracer.dart`).
///
/// Reference: ADR-027 + `docs/PLAN-P56-firebase-performance-traces.md` §3.7.
@Riverpod(keepAlive: true)
PerformanceTracer performanceTracer(PerformanceTracerRef ref) {
  if (kDebugMode) {
    return const NoopPerformanceTracer();
  }
  if (kIsWeb) {
    return const SentryPerformanceTracer();
  }
  final firebase = ref.watch(firebasePerformanceProvider);
  return FirebasePerformanceTracer(firebase);
}
