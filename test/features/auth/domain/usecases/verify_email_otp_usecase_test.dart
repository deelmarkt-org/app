import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/auth/domain/repositories/auth_repository.dart';
import 'package:deelmarkt/features/auth/domain/usecases/verify_email_otp_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late VerifyEmailOtpUseCase useCase;

  setUp(() {
    mockRepo = MockAuthRepository();
    useCase = VerifyEmailOtpUseCase(mockRepo);
  });

  group('VerifyEmailOtpUseCase', () {
    test('delegates to repository on success', () async {
      when(
        () => mockRepo.verifyEmailOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async {});

      await useCase.call(email: 'test@example.com', token: '123456');

      verify(
        () =>
            mockRepo.verifyEmailOtp(email: 'test@example.com', token: '123456'),
      ).called(1);
    });

    test('propagates AuthException', () async {
      when(
        () => mockRepo.verifyEmailOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenThrow(const AuthException('error.otp_invalid'));

      expect(
        () => useCase.call(email: 'test@example.com', token: '000000'),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
