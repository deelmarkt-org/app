import 'package:deelmarkt/features/profile/domain/repositories/settings_repository.dart';
import 'package:deelmarkt/features/profile/domain/usecases/delete_account_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository repository;
  late DeleteAccountUseCase useCase;

  setUp(() {
    repository = MockSettingsRepository();
    useCase = DeleteAccountUseCase(repository: repository);
  });

  group('DeleteAccountUseCase', () {
    test('requires password and delegates to repository', () async {
      when(
        () => repository.deleteAccount(password: any(named: 'password')),
      ).thenAnswer((_) async {});

      await useCase.call(password: 'test-password'); // pragma: allowlist secret
      verify(
        () => repository.deleteAccount(
          password: 'test-password',
        ), // pragma: allowlist secret
      ).called(1);
    });
  });
}
