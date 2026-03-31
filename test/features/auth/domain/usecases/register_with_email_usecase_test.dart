import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/auth/domain/repositories/auth_repository.dart';
import 'package:deelmarkt/features/auth/domain/usecases/register_with_email_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late RegisterWithEmailUseCase useCase;

  setUp(() {
    mockRepo = MockAuthRepository();
    useCase = RegisterWithEmailUseCase(mockRepo);
  });

  final testTime = DateTime(2026, 3, 30);

  group('RegisterWithEmailUseCase', () {
    test('delegates to repository on success', () async {
      when(
        () => mockRepo.registerWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
          termsAcceptedAt: any(named: 'termsAcceptedAt'),
          privacyAcceptedAt: any(named: 'privacyAcceptedAt'),
        ),
      ).thenAnswer((_) async {});

      await useCase.call(
        email: 'test@example.com',
        password: 'Test1234',
        termsAcceptedAt: testTime,
        privacyAcceptedAt: testTime,
      );

      verify(
        () => mockRepo.registerWithEmail(
          email: 'test@example.com',
          password: 'Test1234',
          termsAcceptedAt: testTime,
          privacyAcceptedAt: testTime,
        ),
      ).called(1);
    });

    test('propagates AuthException from repository', () async {
      when(
        () => mockRepo.registerWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
          termsAcceptedAt: any(named: 'termsAcceptedAt'),
          privacyAcceptedAt: any(named: 'privacyAcceptedAt'),
        ),
      ).thenThrow(const AuthException('error.email_taken'));

      expect(
        () => useCase.call(
          email: 'taken@example.com',
          password: 'Test1234',
          termsAcceptedAt: testTime,
          privacyAcceptedAt: testTime,
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
