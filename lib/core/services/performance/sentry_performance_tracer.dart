import 'package:deelmarkt/core/services/performance/performance_tracer.dart';
import 'package:deelmarkt/core/services/performance/trace_attributes.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Web-platform implementation that maps trace operations to Sentry
/// transactions.
///
/// `firebase_performance` web has parity gaps for the custom-trace API; we
/// delegate to Sentry transactions on web only. Trace names + attribute keys
/// are identical across backends so SLO reports normalise downstream.
///
/// Reference: ADR-027 §Web fallback strategy.
class SentryPerformanceTracer implements PerformanceTracer {
  const SentryPerformanceTracer();

  @override
  PerformanceTraceHandle start(String name) {
    final transaction = Sentry.startTransaction(name, 'custom_trace');
    return _SentryHandle(name: name, transaction: transaction);
  }
}

class _SentryHandle implements PerformanceTraceHandle {
  _SentryHandle({required this.name, required ISentrySpan transaction})
    : _transaction = transaction;

  @override
  final String name;
  final ISentrySpan _transaction;
  bool _stopped = false;

  @override
  void putAttribute(String key, String value) {
    if (!TraceAttributes.validateKey(key)) return;
    _transaction.setData(key, value);
  }

  @override
  void putMetric(String key, int value) {
    _transaction.setData(key, value);
  }

  @override
  Future<void> stop() async {
    if (_stopped) return;
    _stopped = true;
    await _transaction.finish();
  }
}
