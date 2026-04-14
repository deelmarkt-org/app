import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';

void main() {
  group('AuthResult sealed class', () {
    test('AuthSuccess equality', () {
      const a = AuthSuccess(userId: 'abc');
      const b = AuthSuccess(userId: 'abc');
      const c = AuthSuccess(userId: 'xyz');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('AuthFailureInvalidCredentials equality', () {
      const a = AuthFailureInvalidCredentials();
      const b = AuthFailureInvalidCredentials();

      expect(a, equals(b));
    });

    test('AuthFailureNetworkError equality', () {
      const a = AuthFailureNetworkError(message: 'timeout');
      const b = AuthFailureNetworkError(message: 'timeout');
      const c = AuthFailureNetworkError(message: 'socket');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('AuthFailureRateLimited equality', () {
      const a = AuthFailureRateLimited(retryAfter: Duration(minutes: 5));
      const b = AuthFailureRateLimited(retryAfter: Duration(minutes: 5));
      const c = AuthFailureRateLimited(retryAfter: Duration(minutes: 10));

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('AuthFailureSessionExpired equality', () {
      const a = AuthFailureSessionExpired();
      const b = AuthFailureSessionExpired();

      expect(a, equals(b));
    });

    test('different subtypes are not equal', () {
      const success = AuthSuccess(userId: 'abc');
      const invalid = AuthFailureInvalidCredentials();
      const network = AuthFailureNetworkError(message: 'err');

      expect(success, isNot(equals(invalid)));
      expect(success, isNot(equals(network)));
      expect(invalid, isNot(equals(network)));
    });

    test('exhaustive switch covers all subtypes', () {
      const AuthResult result = AuthSuccess(userId: 'test');
      final label = switch (result) {
        AuthSuccess() => 'success',
        AuthFailureInvalidCredentials() => 'invalid',
        AuthFailureNetworkError() => 'network',
        AuthFailureRateLimited() => 'rate',
        AuthFailureBiometricUnavailable() => 'bio_unavail',
        AuthFailureBiometricFailed() => 'bio_fail',
        AuthFailureSessionExpired() => 'session',
        AuthFailureUnknown() => 'unknown',
        AuthFailureOAuthCancelled() => 'oauth_cancelled',
        AuthFailureOAuthUnavailable() => 'oauth_unavailable',
      };
      expect(label, 'success');
    });
  });

  group('BiometricMethod', () {
    test('has face and fingerprint values', () {
      expect(BiometricMethod.values, hasLength(2));
      expect(BiometricMethod.values, contains(BiometricMethod.face));
      expect(BiometricMethod.values, contains(BiometricMethod.fingerprint));
    });
  });
}
