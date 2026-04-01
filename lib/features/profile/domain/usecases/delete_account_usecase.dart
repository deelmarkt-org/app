import 'package:deelmarkt/features/profile/domain/repositories/settings_repository.dart';

/// Permanently delete user account.
///
/// Requires [password] for re-authentication (OWASP ASVS L2 §4.2.1).
class DeleteAccountUseCase {
  const DeleteAccountUseCase({required this.repository});

  final SettingsRepository repository;

  Future<void> call({required String password}) {
    return repository.deleteAccount(password: password);
  }
}
