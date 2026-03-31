import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/features/auth/domain/repositories/auth_repository.dart';
import 'package:deelmarkt/features/auth/domain/usecases/send_phone_otp_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late SendPhoneOtpUseCase useCase;

  setUp(() {
    mockRepo = MockAuthRepository();
    useCase = SendPhoneOtpUseCase(mockRepo);
  });

  group('SendPhoneOtpUseCase', () {
    test('normalizes phone and delegates to repository', () async {
      when(
        () => mockRepo.sendPhoneOtp(phone: any(named: 'phone')),
      ).thenAnswer((_) async {});

      await useCase.call(phone: '0612345678');

      // Phone should be normalized to E.164
      verify(() => mockRepo.sendPhoneOtp(phone: '+31612345678')).called(1);
    });

    test('passes already normalized phone through', () async {
      when(
        () => mockRepo.sendPhoneOtp(phone: any(named: 'phone')),
      ).thenAnswer((_) async {});

      await useCase.call(phone: '+31698765432');

      verify(() => mockRepo.sendPhoneOtp(phone: '+31698765432')).called(1);
    });
  });
}
