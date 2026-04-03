import 'package:deelmarkt/features/profile/domain/repositories/settings_repository.dart';

/// Request GDPR data export. Returns a download URL.
class ExportUserDataUseCase {
  const ExportUserDataUseCase({required this.repository});

  final SettingsRepository repository;

  Future<String> call() {
    return repository.exportUserData();
  }
}
