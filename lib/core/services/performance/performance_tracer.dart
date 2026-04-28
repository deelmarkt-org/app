/// Pure-Dart contract for performance instrumentation.
///
/// The interface seam exists so:
///   1. Domain / data layers depend on the interface, not the SDK
///   2. Tests can override with [NoopPerformanceTracer] or a recording fake
///   3. Web (Sentry) and mobile (Firebase Performance) can swap impls at
///      composition time
///
/// Implementations:
///   - `FirebasePerformanceTracer` — mobile production
///   - `SentryPerformanceTracer`   — web production
///   - `NoopPerformanceTracer`     — debug + tests
///
/// Reference: ADR-027 + `docs/PLAN-P56-firebase-performance-traces.md`.
abstract interface class PerformanceTracer {
  /// Start a trace identified by [name]. The returned handle MUST have
  /// [PerformanceTraceHandle.stop] called exactly once.
  ///
  /// [name] should be a constant from `TraceNames`.
  PerformanceTraceHandle start(String name);
}

/// Handle to an in-flight trace.
abstract interface class PerformanceTraceHandle {
  /// The trace name passed to [PerformanceTracer.start]. Useful for logs
  /// and contract assertions.
  String get name;

  /// Add an attribute to the trace.
  ///
  /// [key] MUST be on the allowlist defined in `TraceAttributes`. The
  /// implementation enforces this — a debug build throws on forbidden
  /// keys; a release build silently drops (never leaks PII).
  void putAttribute(String key, String value);

  /// Add a numeric metric to the trace (e.g. sub-step duration).
  void putMetric(String key, int value);

  /// Stop the trace. Idempotent — calling twice is a no-op (and may be
  /// logged as a warning).
  Future<void> stop();
}
