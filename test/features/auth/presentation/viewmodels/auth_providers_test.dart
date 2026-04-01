import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/features/auth/domain/repositories/auth_repository.dart';
import 'package:deelmarkt/features/auth/domain/usecases/register_with_email_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/resend_email_otp_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/send_phone_otp_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/verify_email_otp_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/verify_phone_otp_usecase.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/auth_providers.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late ProviderContainer container;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepository)],
    );
  });

  tearDown(() => container.dispose());

  group('auth_providers', () {
    test('authRepositoryProvider returns the overridden mock', () {
      final repo = container.read(authRepositoryProvider);

      expect(repo, same(mockAuthRepository));
    });

    test(
      'registerWithEmailUseCaseProvider creates RegisterWithEmailUseCase',
      () {
        final useCase = container.read(registerWithEmailUseCaseProvider);

        expect(useCase, isA<RegisterWithEmailUseCase>());
      },
    );

    test('resendEmailOtpUseCaseProvider creates ResendEmailOtpUseCase', () {
      final useCase = container.read(resendEmailOtpUseCaseProvider);

      expect(useCase, isA<ResendEmailOtpUseCase>());
    });

    test('verifyEmailOtpUseCaseProvider creates VerifyEmailOtpUseCase', () {
      final useCase = container.read(verifyEmailOtpUseCaseProvider);

      expect(useCase, isA<VerifyEmailOtpUseCase>());
    });

    test('sendPhoneOtpUseCaseProvider creates SendPhoneOtpUseCase', () {
      final useCase = container.read(sendPhoneOtpUseCaseProvider);

      expect(useCase, isA<SendPhoneOtpUseCase>());
    });

    test('verifyPhoneOtpUseCaseProvider creates VerifyPhoneOtpUseCase', () {
      final useCase = container.read(verifyPhoneOtpUseCaseProvider);

      expect(useCase, isA<VerifyPhoneOtpUseCase>());
    });

    test('each provider read returns a new instance (auto-dispose)', () {
      final useCase1 = container.read(registerWithEmailUseCaseProvider);

      // Dispose and recreate container to verify auto-dispose behavior.
      container.dispose();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );

      final useCase2 = container.read(registerWithEmailUseCaseProvider);

      // Different container produces different instance.
      expect(identical(useCase1, useCase2), isFalse);
    });
  });
}
