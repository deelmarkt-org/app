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
    test('completes without error', () async {
      when(() => repository.deleteAccount()).thenAnswer((_) async {});

      await expectLater(useCase.call(), completes);
      verify(() => repository.deleteAccount()).called(1);
    });
  });
}
