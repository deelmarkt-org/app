import 'package:deelmarkt/features/profile/domain/entities/notification_preferences.dart';
import 'package:deelmarkt/features/profile/domain/repositories/settings_repository.dart';
import 'package:deelmarkt/features/profile/domain/usecases/update_notification_prefs_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late MockSettingsRepository repository;
  late UpdateNotificationPrefsUseCase useCase;

  setUpAll(() {
    registerFallbackValue(const NotificationPreferences());
  });

  setUp(() {
    repository = MockSettingsRepository();
    useCase = UpdateNotificationPrefsUseCase(repository: repository);
  });

  group('UpdateNotificationPrefsUseCase', () {
    test('updates and returns new preferences', () async {
      const input = NotificationPreferences(
        messages: false,
        shippingUpdates: false,
        marketing: true,
      );
      when(
        () => repository.updateNotificationPreferences(input),
      ).thenAnswer((_) async => input);

      final result = await useCase.call(input);

      expect(result, equals(input));
      verify(() => repository.updateNotificationPreferences(input)).called(1);
    });

    test('passes preferences through to repository', () async {
      const prefs = NotificationPreferences(marketing: true);
      when(
        () => repository.updateNotificationPreferences(prefs),
      ).thenAnswer((_) async => prefs);

      await useCase.call(prefs);

      verify(() => repository.updateNotificationPreferences(prefs)).called(1);
    });
  });
}
