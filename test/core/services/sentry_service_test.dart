import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:deelmarkt/core/services/sentry_service.dart';

void main() {
  group('initSentry', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('completes without throwing', () async {
      await expectLater(initSentry(), completes);
    });

    test('Sentry is disabled in debug mode (empty DSN)', () async {
      await initSentry();
      expect(Sentry.isEnabled, isFalse);
    });
  });

  group('sentryCaptureException', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('returns SentryId when Sentry is disabled', () async {
      final id = await sentryCaptureException(Exception('test error'));
      expect(id, isA<SentryId>());
    });

    test('accepts optional stackTrace parameter', () async {
      final id = await sentryCaptureException(
        Exception('test'),
        stackTrace: StackTrace.current,
      );
      expect(id, isA<SentryId>());
    });
  });

  group('sentryCaptureMessage', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('returns SentryId when Sentry is disabled', () async {
      final id = await sentryCaptureMessage('test message');
      expect(id, isA<SentryId>());
    });
  });
}
