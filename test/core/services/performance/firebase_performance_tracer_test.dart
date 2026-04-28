import 'package:deelmarkt/core/services/performance/firebase_performance_tracer.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebasePerformance extends Mock implements FirebasePerformance {}

class _MockTrace extends Mock implements Trace {}

void main() {
  late _MockFirebasePerformance firebase;
  late _MockTrace trace;
  late FirebasePerformanceTracer tracer;

  setUp(() {
    firebase = _MockFirebasePerformance();
    trace = _MockTrace();
    when(() => firebase.newTrace(any())).thenReturn(trace);
    when(() => trace.start()).thenAnswer((_) async {});
    when(() => trace.stop()).thenAnswer((_) async {});
    tracer = FirebasePerformanceTracer(firebase);
  });

  group('FirebasePerformanceTracer.start', () {
    test('creates and starts a trace with the given name', () {
      tracer.start('app_start');

      verify(() => firebase.newTrace('app_start')).called(1);
      verify(() => trace.start()).called(1);
    });

    test('returned handle exposes the trace name', () {
      final handle = tracer.start('listing_load');

      expect(handle.name, 'listing_load');
    });
  });

  group('FirebasePerformanceTracer handle.putAttribute', () {
    test('delegates to Trace.putAttribute for allowlisted keys', () {
      tracer.start('search_query').putAttribute('locale', 'nl');

      verify(() => trace.putAttribute('locale', 'nl')).called(1);
    });

    test('throws ArgumentError in debug for forbidden keys', () {
      final handle = tracer.start('listing_load');

      // kDebugMode is true under flutter test → validateKey throws.
      expect(
        () => handle.putAttribute('user_id', 'abc'),
        throwsA(isA<ArgumentError>()),
      );
      verifyNever(() => trace.putAttribute(any(), any()));
    });
  });

  group('FirebasePerformanceTracer handle.putMetric', () {
    test('delegates to Trace.setMetric', () {
      tracer.start('listing_load').putMetric('rows', 42);

      verify(() => trace.setMetric('rows', 42)).called(1);
    });
  });

  group('FirebasePerformanceTracer handle.stop', () {
    test('delegates to Trace.stop exactly once', () async {
      final handle = tracer.start('app_start');
      await handle.stop();

      verify(() => trace.stop()).called(1);
    });

    test('idempotent — second stop does not call Trace.stop again', () async {
      final handle = tracer.start('app_start');
      await handle.stop();
      await handle.stop();

      verify(() => trace.stop()).called(1);
    });
  });
}
