import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:deelmarkt/core/services/performance/performance_tracer.dart';
import 'package:deelmarkt/core/services/performance/trace_attributes.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Factory signature so tests can inject a mock span without coupling
/// to the Sentry SDK static singleton. Production callers use the
/// default constructor which delegates to [Sentry.startTransaction].
typedef SentryTransactionFactory =
    ISentrySpan Function(String name, String operation);

/// Sentry transaction `op` for every facade-managed transaction.
///
/// Sentry uses `op` to group transactions in the Performance dashboard and
/// distinguish them from auto-instrumented ones (e.g. `http.client`,
/// `navigation`, `db.query`). All custom traces from this facade are
/// uniformly tagged so dashboards can filter precisely. Per CLAUDE.md §3.3
/// — never magic strings — extracted as a constant for symbolic clarity
/// and so tests can assert the operation passed to the SDK.
@visibleForTesting
const String sentryFacadeOperation = 'custom_trace';

ISentrySpan _defaultTransactionFactory(String name, String operation) =>
    Sentry.startTransaction(name, operation);

/// Web-platform implementation that maps trace operations to Sentry
/// transactions.
///
/// `firebase_performance` web has parity gaps for the custom-trace API; we
/// delegate to Sentry transactions on web only. Trace names + attribute keys
/// are identical across backends so SLO reports normalise downstream.
///
/// Reference: ADR-027 §Web fallback strategy.
class SentryPerformanceTracer implements PerformanceTracer {
  const SentryPerformanceTracer({
    SentryTransactionFactory transactionFactory = _defaultTransactionFactory,
  }) : _factory = transactionFactory;

  final SentryTransactionFactory _factory;

  @override
  PerformanceTraceHandle start(String name) {
    final transaction = _factory(name, sentryFacadeOperation);
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
    // Length + control-char check before sending to Sentry tag indexing.
    // Sentry tags propagate to Discover queries, alerts, and BigQuery
    // exports — injected newlines could pollute downstream log shippers.
    // Per security review PR #220 H-2.
    if (!TraceAttributes.validateValue(value)) return;
    // Tags are indexed and searchable in Sentry's Discover/Performance
    // dashboards; setData would write to "extra" context which is not
    // queryable. Per Gemini PR #220 review.
    _transaction.setTag(key, value);
  }

  @override
  void putMetric(String key, int value) {
    // setMeasurement is the canonical Sentry API for numeric metrics
    // attached to a transaction; it surfaces in the Performance UI as
    // a first-class metric and supports aggregation. Per Gemini PR #220
    // review.
    _transaction.setMeasurement(key, value);
  }

  @override
  Future<void> stop() async {
    if (_stopped) return;
    _stopped = true;
    await _transaction.finish();
  }
}
