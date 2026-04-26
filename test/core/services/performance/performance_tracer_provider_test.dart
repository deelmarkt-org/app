import 'package:deelmarkt/core/services/performance/noop_performance_tracer.dart';
import 'package:deelmarkt/core/services/performance/performance_tracer_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('performanceTracerProvider', () {
    test(
      'returns NoopPerformanceTracer in debug mode (kDebugMode == true)',
      () {
        // flutter test runs with kDebugMode == true by default. The provider
        // therefore short-circuits to NoopPerformanceTracer regardless of
        // platform — keeping tests deterministic and free of Firebase init.
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final tracer = container.read(performanceTracerProvider);

        expect(tracer, isA<NoopPerformanceTracer>());
      },
    );

    test('keepAlive=true: same instance across multiple reads', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final first = container.read(performanceTracerProvider);
      final second = container.read(performanceTracerProvider);

      expect(identical(first, second), isTrue);
    });
  });
}
