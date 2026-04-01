import 'package:deelmarkt/features/profile/domain/entities/notification_preferences.dart';
import 'package:deelmarkt/features/profile/domain/repositories/settings_repository.dart';

/// Update notification preferences.
class UpdateNotificationPrefsUseCase {
  const UpdateNotificationPrefsUseCase({required this.repository});

  final SettingsRepository repository;

  Future<NotificationPreferences> call(NotificationPreferences prefs) {
    return repository.updateNotificationPreferences(prefs);
  }
}
