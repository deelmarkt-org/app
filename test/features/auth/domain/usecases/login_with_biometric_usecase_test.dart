import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';
import 'package:deelmarkt/features/auth/domain/repositories/auth_repository.dart';
import 'package:deelmarkt/features/auth/domain/usecases/login_with_biometric_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late LoginWithBiometricUseCase useCase;

  setUp(() {
    mockRepo = MockAuthRepository();
    useCase = LoginWithBiometricUseCase(repository: mockRepo);
  });

  group('LoginWithBiometricUseCase', () {
    const reason = 'test biometric reason';

    test('returns unavailable when biometric is not available', () async {
      when(() => mockRepo.isBiometricAvailable).thenAnswer((_) async => false);

      final result = await useCase(localizedReason: reason);

      expect(result, isA<AuthFailureBiometricUnavailable>());
      verifyNever(
        () => mockRepo.loginWithBiometric(
          localizedReason: any(named: 'localizedReason'),
        ),
      );
    });

    test('delegates to repository when biometric is available', () async {
      when(() => mockRepo.isBiometricAvailable).thenAnswer((_) async => true);
      when(
        () => mockRepo.loginWithBiometric(localizedReason: reason),
      ).thenAnswer((_) async => const AuthSuccess(userId: '123'));

      final result = await useCase(localizedReason: reason);

      expect(result, isA<AuthSuccess>());
      verify(
        () => mockRepo.loginWithBiometric(localizedReason: reason),
      ).called(1);
    });

    test('returns biometric failed when repository fails', () async {
      when(() => mockRepo.isBiometricAvailable).thenAnswer((_) async => true);
      when(
        () => mockRepo.loginWithBiometric(localizedReason: reason),
      ).thenAnswer((_) async => const AuthFailureBiometricFailed());

      final result = await useCase(localizedReason: reason);

      expect(result, isA<AuthFailureBiometricFailed>());
    });
  });
}
