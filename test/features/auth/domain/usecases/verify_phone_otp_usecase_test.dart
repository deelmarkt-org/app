import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/auth/domain/repositories/auth_repository.dart';
import 'package:deelmarkt/features/auth/domain/usecases/verify_phone_otp_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late VerifyPhoneOtpUseCase useCase;

  setUp(() {
    mockRepo = MockAuthRepository();
    useCase = VerifyPhoneOtpUseCase(mockRepo);
  });

  group('VerifyPhoneOtpUseCase', () {
    test('delegates to repository on success', () async {
      when(
        () => mockRepo.verifyPhoneOtp(
          phone: any(named: 'phone'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async {});

      await useCase.call(phone: '+31612345678', token: '123456');

      verify(
        () => mockRepo.verifyPhoneOtp(phone: '+31612345678', token: '123456'),
      ).called(1);
    });

    test('propagates AuthException', () async {
      when(
        () => mockRepo.verifyPhoneOtp(
          phone: any(named: 'phone'),
          token: any(named: 'token'),
        ),
      ).thenThrow(const AuthException('error.otp_invalid'));

      expect(
        () => useCase.call(phone: '+31612345678', token: '000000'),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
