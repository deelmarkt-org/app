import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:deelmarkt/core/services/sentry_service.dart';

void main() {
  group('initSentry', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('completes without throwing', () async {
      // initSentry sets DSN to empty string in debug mode, so no
      // network calls are made — safe for CI.
      await expectLater(initSentry(), completes);
    });

    test('Sentry is disabled in debug mode (empty DSN)', () async {
      await initSentry();

      // With an empty DSN Sentry does not send events.
      expect(Sentry.isEnabled, isFalse);
    });
  });

  group('sentryCaptureException', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('does not throw when Sentry is not initialised', () async {
      // Should gracefully no-op when DSN is empty / Sentry disabled.
      await expectLater(
        sentryCaptureException(Exception('test error')),
        completes,
      );
    });

    test('accepts optional stackTrace parameter', () async {
      await expectLater(
        sentryCaptureException(
          Exception('test'),
          stackTrace: StackTrace.current,
        ),
        completes,
      );
    });
  });

  group('sentryCaptureMessage', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('does not throw when Sentry is not initialised', () async {
      await expectLater(sentryCaptureMessage('test message'), completes);
    });
  });
}
