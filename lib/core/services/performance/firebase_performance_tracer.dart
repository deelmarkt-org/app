import 'package:deelmarkt/core/services/performance/performance_tracer.dart';
import 'package:deelmarkt/core/services/performance/trace_attributes.dart';
import 'package:firebase_performance/firebase_performance.dart';

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
    final trace = _firebasePerformance.newTrace(name)..start();
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
