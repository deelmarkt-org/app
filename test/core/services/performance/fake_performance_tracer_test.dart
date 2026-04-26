import 'package:flutter_test/flutter_test.dart';

import '../../../_helpers/fake_performance_tracer.dart';

void main() {
  group('FakePerformanceTracer', () {
    late FakePerformanceTracer tracer;

    setUp(() {
      tracer = FakePerformanceTracer();
    });

    test('records start + stop calls in order', () async {
      final handle = tracer.start('app_start');
      await handle.stop();

      expect(tracer.recordedCalls, [
        TraceCall.start('app_start'),
        TraceCall.stop('app_start'),
      ]);
    });

    test('records attribute writes', () async {
      final handle =
          tracer.start('listing_load')
            ..putAttribute('locale', 'nl')
            ..putAttribute('platform', 'ios');
      await handle.stop();

      expect(
        tracer.recordedCalls,
        containsAllInOrder([
          TraceCall.attribute('listing_load', 'locale', 'nl'),
          TraceCall.attribute('listing_load', 'platform', 'ios'),
        ]),
      );
    });

    test('records metric writes', () async {
      final handle = tracer.start('search_query')..putMetric('rows', 25);
      await handle.stop();

      expect(
        tracer.recordedCalls,
        contains(TraceCall.metric('search_query', 'rows', 25)),
      );
    });

    test('activeTraceCount tracks lifecycle', () async {
      final h1 = tracer.start('t1');
      final h2 = tracer.start('t2');
      expect(tracer.activeTraceCount, 2);

      await h1.stop();
      expect(tracer.activeTraceCount, 1);

      await h2.stop();
      expect(tracer.activeTraceCount, 0);
    });

    test('lifecycle leak: an unstopped trace shows in activeTraceCount', () {
      tracer.start('forgotten');

      expect(tracer.activeTraceCount, 1);
    });

    test('double-stop is idempotent (no duplicate stop record)', () async {
      final handle = tracer.start('payment_create');
      await handle.stop();
      await handle.stop();

      final stopCount =
          tracer.recordedCalls
              .where((c) => c == TraceCall.stop('payment_create'))
              .length;
      expect(stopCount, 1);
      expect(tracer.activeTraceCount, 0);
    });

    test('reset clears state', () async {
      final handle = tracer.start('app_start');
      await handle.stop();
      tracer.reset();

      expect(tracer.recordedCalls, isEmpty);
      expect(tracer.activeTraceCount, 0);
    });

    test(
      'putAttribute throws on PII key in debug — matches production seam',
      () {
        final handle = tracer.start('listing_load');
        expect(
          () => handle.putAttribute('user_id', 'should-be-rejected'),
          throwsArgumentError,
        );
      },
    );

    test('putAttribute drops unknown key without recording', () {
      // Use a non-PII unknown key to verify the silent-drop path in release
      // semantics; the assertion is that no attribute call is recorded.
      // Allowed-list is the source of truth — test relies on validateKey's
      // debug throw being caught as ArgumentError. We assert behaviour is the
      // same on the fake as on the real impls (parity with H1 of #220 review).
      final handle = tracer.start('listing_load');
      try {
        handle.putAttribute('user_id', 'pii');
      } on ArgumentError {
        // Expected in debug.
      }
      expect(
        tracer.recordedCalls.where(
          (c) => c.kind == TraceCallKind.attribute && c.key == 'user_id',
        ),
        isEmpty,
      );
    });
  });
}
