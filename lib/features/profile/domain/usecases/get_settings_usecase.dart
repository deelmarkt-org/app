import 'package:deelmarkt/features/profile/domain/entities/notification_preferences.dart';
import 'package:deelmarkt/features/profile/domain/repositories/settings_repository.dart';

/// Get current notification preferences.
class GetSettingsUseCase {
  const GetSettingsUseCase({required this.repository});

  final SettingsRepository repository;

  Future<NotificationPreferences> call() {
    return repository.getNotificationPreferences();
  }
}
