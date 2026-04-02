import 'package:deelmarkt/features/profile/domain/repositories/settings_repository.dart';
import 'package:deelmarkt/features/profile/domain/usecases/export_user_data_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository repository;
  late ExportUserDataUseCase useCase;

  setUp(() {
    repository = MockSettingsRepository();
    useCase = ExportUserDataUseCase(repository: repository);
  });

  group('ExportUserDataUseCase', () {
    test('returns export URL from repository', () async {
      const expectedUrl = 'https://deelmarkt.nl/export/data.zip';
      when(
        () => repository.exportUserData(),
      ).thenAnswer((_) async => expectedUrl);

      final result = await useCase.call();

      expect(result, equals(expectedUrl));
      verify(() => repository.exportUserData()).called(1);
    });
  });
}
