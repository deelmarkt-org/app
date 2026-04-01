import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';
import 'package:deelmarkt/features/auth/domain/repositories/auth_repository.dart';
import 'package:deelmarkt/features/auth/domain/usecases/login_with_email_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late LoginWithEmailUseCase useCase;

  setUp(() {
    mockRepo = MockAuthRepository();
    useCase = LoginWithEmailUseCase(repository: mockRepo);
  });

  group('LoginWithEmailUseCase', () {
    test('normalises email — trims and lowercases', () async {
      when(
        () => mockRepo.loginWithEmail(
          email: 'user@example.com',
          password: 'password123', // pragma: allowlist secret
        ),
      ).thenAnswer((_) async => const AuthSuccess(userId: '123'));

      await useCase(
        email: '  User@Example.COM  ',
        password: 'password123', // pragma: allowlist secret
      );

      verify(
        () => mockRepo.loginWithEmail(
          email: 'user@example.com',
          password: 'password123', // pragma: allowlist secret
        ),
      ).called(1);
    });

    test('delegates to repository and returns result unchanged', () async {
      const expected = AuthFailureInvalidCredentials();
      when(
        () => mockRepo.loginWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => expected);

      final result = await useCase(
        email: 'test@test.com',
        password: 'wrong', // pragma: allowlist secret
      );

      expect(result, equals(expected));
    });

    test('passes password through unmodified', () async {
      when(
        () => mockRepo.loginWithEmail(
          email: any(named: 'email'),
          password: 'P@ssw0rd!', // pragma: allowlist secret
        ),
      ).thenAnswer((_) async => const AuthSuccess(userId: '1'));

      await useCase(
        email: 'a@b.c',
        password: 'P@ssw0rd!', // pragma: allowlist secret
      );

      verify(
        () => mockRepo.loginWithEmail(
          email: any(named: 'email'),
          password: 'P@ssw0rd!', // pragma: allowlist secret
        ),
      ).called(1);
    });
  });
}
