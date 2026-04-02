import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';

void main() {
  late MockAuthRepository repo;

  setUp(() {
    repo = MockAuthRepository();
  });

  group('MockAuthRepository', () {
    test('registerWithEmail completes without error', () async {
      await expectLater(
        repo.registerWithEmail(
          email: 'test@example.com',
          password: 'Password1!', // pragma: allowlist secret
          termsAcceptedAt: DateTime(2026),
          privacyAcceptedAt: DateTime(2026),
        ),
        completes,
      );
    });

    test('verifyEmailOtp completes without error', () async {
      await expectLater(
        repo.verifyEmailOtp(email: 'test@example.com', token: '123456'),
        completes,
      );
    });

    test('resendEmailOtp completes without error', () async {
      await expectLater(
        repo.resendEmailOtp(email: 'test@example.com'),
        completes,
      );
    });

    test('sendPhoneOtp completes without error', () async {
      await expectLater(repo.sendPhoneOtp(phone: '+31612345678'), completes);
    });

    test('verifyPhoneOtp completes without error', () async {
      await expectLater(
        repo.verifyPhoneOtp(phone: '+31612345678', token: '123456'),
        completes,
      );
    });

    test('loginWithEmail returns AuthSuccess for valid credentials', () async {
      final result = await repo.loginWithEmail(
        email: 'test@example.com',
        password: 'correct', // pragma: allowlist secret
      );

      expect(result, isA<AuthSuccess>());
      expect((result as AuthSuccess).userId, 'mock-user-id');
    });

    test(
      'loginWithEmail returns AuthFailureInvalidCredentials for wrong password',
      () async {
        final result = await repo.loginWithEmail(
          email: 'test@example.com',
          password: 'wrong', // pragma: allowlist secret
        );

        expect(result, isA<AuthFailureInvalidCredentials>());
      },
    );

    test('loginWithBiometric returns AuthSuccess', () async {
      final result = await repo.loginWithBiometric(
        localizedReason: 'Authenticate',
      );

      expect(result, isA<AuthSuccess>());
      expect((result as AuthSuccess).userId, 'mock-user-id');
    });

    test('isBiometricAvailable returns false', () async {
      final available = await repo.isBiometricAvailable;
      expect(available, isFalse);
    });

    test('availableBiometricMethod returns null', () async {
      final method = await repo.availableBiometricMethod;
      expect(method, isNull);
    });

    test('initiateIdinVerification returns a URL', () async {
      final url = await repo.initiateIdinVerification();
      expect(url, contains('idin.nl'));
      expect(url, startsWith('https://'));
    });
  });
}
