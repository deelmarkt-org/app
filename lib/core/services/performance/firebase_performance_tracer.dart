import 'package:deelmarkt/core/services/performance/performance_tracer.dart';
import 'package:deelmarkt/core/services/performance/trace_attributes.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Mobile-platform implementation backed by Firebase Performance Monitoring.
///
/// Wraps [FirebasePerformance.instance]. Every public mutation enforces the
/// [TraceAttributes] allowlist before delegating to the SDK so a forbidden
/// attribute can never leak into the BigQuery export.
class FirebasePerformanceTracer implements PerformanceTracer {
  FirebasePerformanceTracer(this._firebasePerformance);

  final FirebasePerformance _firebasePerformance;

  @override
  PerformanceTraceHandle start(String name) {
    // Fire-and-forget: SDK contract returns a Future but the handle is
    // valid immediately. Awaiting would force every call site async.
    //
    // Async failures from `_trace.start()` would otherwise be silently
    // dropped (no zone handler) — route them to Sentry so we know if a
    // backend regression starts breaking custom traces. The trace handle
    // itself is still valid, so observability degrades gracefully (no
    // metrics for that trace, but no crash, no Future-error).
    final trace = _firebasePerformance.newTrace(name);
    trace.start().catchError((Object e, StackTrace st) {
      Sentry.captureException(e, stackTrace: st);
    });
    return _FirebaseHandle(name: name, trace: trace);
  }
}

class _FirebaseHandle implements PerformanceTraceHandle {
  _FirebaseHandle({required this.name, required Trace trace}) : _trace = trace;

  @override
  final String name;
  final Trace _trace;
  bool _stopped = false;

  @override
  void putAttribute(String key, String value) {
    if (!TraceAttributes.validateKey(key)) return;
    if (!TraceAttributes.validateValue(value)) return;
    _trace.putAttribute(key, value);
  }

  @override
  void putMetric(String key, int value) {
    _trace.setMetric(key, value);
  }

  @override
  Future<void> stop() async {
    if (_stopped) return;
    _stopped = true;
    await _trace.stop();
  }
}
