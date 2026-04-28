import 'package:deelmarkt/core/services/performance/noop_performance_tracer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NoopPerformanceTracer', () {
    test('start returns a handle that exposes the trace name', () {
      const tracer = NoopPerformanceTracer();
      final handle = tracer.start('app_start');

      expect(handle.name, 'app_start');
    });

    test('handle accepts attribute and metric writes without error', () {
      const tracer = NoopPerformanceTracer();
      tracer.start('listing_load')
        ..putAttribute('locale', 'nl')
        ..putMetric('rows', 42);

      // No assertion needed: the contract is "no exception".
    });

    test('handle.stop is idempotent', () async {
      const tracer = NoopPerformanceTracer();
      final handle = tracer.start('search_query');

      await handle.stop();
      await handle.stop();

      // Calling twice must not throw.
    });
  });
}
