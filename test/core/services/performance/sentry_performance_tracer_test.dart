import 'package:deelmarkt/core/services/performance/sentry_performance_tracer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class _MockSpan extends Mock implements ISentrySpan {}

void main() {
  late _MockSpan span;
  late SentryPerformanceTracer tracer;
  late List<({String name, String op})> startedTransactions;

  setUp(() {
    span = _MockSpan();
    when(() => span.finish()).thenAnswer((_) async {});
    when(() => span.setTag(any(), any())).thenAnswer((_) async {});
    when(() => span.setMeasurement(any(), any())).thenAnswer((_) async {});

    startedTransactions = [];
    tracer = SentryPerformanceTracer(
      transactionFactory: (name, op) {
        startedTransactions.add((name: name, op: op));
        return span;
      },
    );
  });

  group('SentryPerformanceTracer.start', () {
    test('invokes the transaction factory with name + custom_trace op', () {
      tracer.start('listing_load');

      expect(startedTransactions, [(name: 'listing_load', op: 'custom_trace')]);
    });

    test('returned handle exposes the trace name', () {
      final handle = tracer.start('app_start');

      expect(handle.name, 'app_start');
    });
  });

  group('SentryPerformanceTracer handle.putAttribute', () {
    test('delegates to span.setTag (indexed in Sentry Discover)', () {
      tracer.start('search_query').putAttribute('locale', 'nl');

      verify(() => span.setTag('locale', 'nl')).called(1);
    });

    test('throws ArgumentError in debug for forbidden PII keys', () {
      final handle = tracer.start('listing_load');

      expect(
        () => handle.putAttribute('user_id', 'abc'),
        throwsA(isA<ArgumentError>()),
      );
      verifyNever(() => span.setTag(any(), any()));
    });
  });

  group('SentryPerformanceTracer handle.putMetric', () {
    test('delegates to span.setMeasurement (Performance UI metric)', () {
      tracer.start('listing_load').putMetric('rows', 42);

      verify(() => span.setMeasurement('rows', 42)).called(1);
    });
  });

  group('SentryPerformanceTracer handle.stop', () {
    test('delegates to span.finish exactly once', () async {
      final handle = tracer.start('app_start');
      await handle.stop();

      verify(() => span.finish()).called(1);
    });

    test('idempotent — second stop does not call finish again', () async {
      final handle = tracer.start('app_start');
      await handle.stop();
      await handle.stop();

      verify(() => span.finish()).called(1);
    });
  });
}
