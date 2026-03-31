import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/exceptions/app_exception.dart';

void main() {
  group('AppException hierarchy', () {
    test('AuthException stores messageKey', () {
      const e = AuthException('error.email_taken');
      expect(e.messageKey, 'error.email_taken');
      expect(e.debugMessage, isNull);
    });

    test('NetworkException uses default messageKey', () {
      const e = NetworkException(debugMessage: 'timeout');
      expect(e.messageKey, 'error.network');
      expect(e.debugMessage, 'timeout');
    });

    test('ValidationException stores messageKey', () {
      const e = ValidationException('validation.email_invalid');
      expect(e.messageKey, 'validation.email_invalid');
    });

    test('sealed class supports exhaustive switch', () {
      const AppException e = AuthException('test');
      final result = switch (e) {
        AuthException() => 'auth',
        NetworkException() => 'network',
        ValidationException() => 'validation',
      };
      expect(result, 'auth');
    });

    test('toString includes type and messageKey', () {
      const e = AuthException('error.generic');
      expect(e.toString(), 'AuthException(error.generic)');
    });
  });
}
