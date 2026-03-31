import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/auth/domain/repositories/auth_repository.dart';
import 'package:deelmarkt/features/auth/domain/usecases/resend_email_otp_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late ResendEmailOtpUseCase useCase;

  setUp(() {
    mockRepo = MockAuthRepository();
    useCase = ResendEmailOtpUseCase(mockRepo);
  });

  group('ResendEmailOtpUseCase', () {
    test('delegates to repository on success', () async {
      when(
        () => mockRepo.resendEmailOtp(email: any(named: 'email')),
      ).thenAnswer((_) async {});

      await useCase.call(email: 'test@example.com');

      verify(
        () => mockRepo.resendEmailOtp(email: 'test@example.com'),
      ).called(1);
    });

    test('propagates AuthException from repository', () async {
      when(
        () => mockRepo.resendEmailOtp(email: any(named: 'email')),
      ).thenThrow(const AuthException('error.rate_limit'));

      expect(
        () => useCase.call(email: 'test@example.com'),
        throwsA(isA<AuthException>()),
      );
    });

    test('propagates NetworkException from repository', () async {
      when(
        () => mockRepo.resendEmailOtp(email: any(named: 'email')),
      ).thenThrow(const NetworkException());

      expect(
        () => useCase.call(email: 'test@example.com'),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
