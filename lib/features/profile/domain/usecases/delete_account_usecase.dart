import 'package:deelmarkt/features/profile/domain/repositories/settings_repository.dart';

/// Permanently delete user account.
class DeleteAccountUseCase {
  const DeleteAccountUseCase({required this.repository});

  final SettingsRepository repository;

  Future<void> call() {
    return repository.deleteAccount();
  }
}
