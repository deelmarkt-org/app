import 'package:deelmarkt/features/profile/domain/entities/notification_preferences.dart';
import 'package:deelmarkt/features/profile/domain/repositories/settings_repository.dart';
import 'package:deelmarkt/features/profile/domain/usecases/get_settings_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository repository;
  late GetSettingsUseCase useCase;

  setUp(() {
    repository = MockSettingsRepository();
    useCase = GetSettingsUseCase(repository: repository);
  });

  group('GetSettingsUseCase', () {
    test('returns notification preferences from repository', () async {
      const expected = NotificationPreferences(offers: false, marketing: true);
      when(
        () => repository.getNotificationPreferences(),
      ).thenAnswer((_) async => expected);

      final result = await useCase.call();

      expect(result, equals(expected));
      verify(() => repository.getNotificationPreferences()).called(1);
    });

    test('returns default preferences', () async {
      const expected = NotificationPreferences();
      when(
        () => repository.getNotificationPreferences(),
      ).thenAnswer((_) async => expected);

      final result = await useCase.call();

      expect(result, equals(expected));
    });
  });
}
