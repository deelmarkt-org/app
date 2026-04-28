import 'package:deelmarkt/core/services/performance/performance_tracer.dart';
import 'package:deelmarkt/core/services/performance/trace_attributes.dart';

/// Test double that records every interaction so assertions can inspect
/// trace lifecycle, attribute writes, and metric writes.
///
/// `putAttribute` routes through [TraceAttributes.validateKey] so a forbidden
/// PII key fails fast in widget/unit tests — matches the production seam's
/// strictness and defends Phase B call-site wiring (per PR #220 review nit).
///
/// Use via `ProviderScope.overrides`:
///
/// ```
/// final fake = FakePerformanceTracer();
/// ProviderScope(
///   overrides: [performanceTracerProvider.overrideWithValue(fake)],
///   child: ...,
/// );
/// // ...exercise code...
/// expect(fake.recordedCalls, contains(TraceCall.start('listing_load')));
/// expect(fake.activeTraceCount, 0);
/// ```
class FakePerformanceTracer implements PerformanceTracer {
  final List<TraceCall> recordedCalls = [];
  final List<_FakeHandle> _active = [];

  /// Number of traces still in-flight (not yet stopped).
  int get activeTraceCount => _active.length;

  @override
  PerformanceTraceHandle start(String name) {
    recordedCalls.add(TraceCall.start(name));
    final handle = _FakeHandle(name: name, owner: this);
    _active.add(handle);
    return handle;
  }

  void _onStop(_FakeHandle handle) {
    _active.remove(handle);
    recordedCalls.add(TraceCall.stop(handle.name));
  }

  /// Reset the recorder between tests.
  void reset() {
    recordedCalls.clear();
    _active.clear();
  }
}

class _FakeHandle implements PerformanceTraceHandle {
  _FakeHandle({required this.name, required this.owner});

  @override
  final String name;
  final FakePerformanceTracer owner;
  bool _stopped = false;

  @override
  void putAttribute(String key, String value) {
    // Enforce the allowlist in tests so PII regressions surface at unit-test
    // time, not only when a real Firebase / Sentry impl runs in debug.
    if (!TraceAttributes.validateKey(key)) return;
    owner.recordedCalls.add(TraceCall.attribute(name, key, value));
  }

  @override
  void putMetric(String key, int value) {
    owner.recordedCalls.add(TraceCall.metric(name, key, value));
  }

  @override
  Future<void> stop() async {
    if (_stopped) return;
    _stopped = true;
    owner._onStop(this);
  }
}

/// One recorded interaction with the fake tracer.
class TraceCall {
  TraceCall._(this.kind, this.traceName, [this.key, this.value]);

  factory TraceCall.start(String name) =>
      TraceCall._(TraceCallKind.start, name);
  factory TraceCall.stop(String name) => TraceCall._(TraceCallKind.stop, name);
  factory TraceCall.attribute(String name, String key, String value) =>
      TraceCall._(TraceCallKind.attribute, name, key, value);
  factory TraceCall.metric(String name, String key, int value) =>
      TraceCall._(TraceCallKind.metric, name, key, value);

  final TraceCallKind kind;
  final String traceName;
  final String? key;
  final Object? value;

  @override
  bool operator ==(Object other) =>
      other is TraceCall &&
      other.kind == kind &&
      other.traceName == traceName &&
      other.key == key &&
      other.value == value;

  @override
  int get hashCode => Object.hash(kind, traceName, key, value);

  @override
  String toString() {
    switch (kind) {
      case TraceCallKind.start:
        return 'start($traceName)';
      case TraceCallKind.stop:
        return 'stop($traceName)';
      case TraceCallKind.attribute:
        return 'attribute($traceName, $key=$value)';
      case TraceCallKind.metric:
        return 'metric($traceName, $key=$value)';
    }
  }
}

enum TraceCallKind { start, stop, attribute, metric }
