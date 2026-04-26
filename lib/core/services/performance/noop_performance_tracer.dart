import 'package:deelmarkt/core/services/performance/performance_tracer.dart';

/// No-op tracer used in debug builds and as the default test double.
///
/// Records no state, performs no I/O — the cheapest possible
/// implementation. Real-mode timing is not affected.
class NoopPerformanceTracer implements PerformanceTracer {
  const NoopPerformanceTracer();

  @override
  PerformanceTraceHandle start(String name) => _NoopHandle(name);
}

class _NoopHandle implements PerformanceTraceHandle {
  _NoopHandle(this.name);

  @override
  final String name;

  @override
  void putAttribute(String key, String value) {}

  @override
  void putMetric(String key, int value) {}

  @override
  Future<void> stop() async {}
}
