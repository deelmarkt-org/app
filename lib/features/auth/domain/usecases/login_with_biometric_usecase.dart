import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';
import 'package:deelmarkt/features/auth/domain/repositories/auth_repository.dart';

/// Checks biometric availability before delegating to [AuthRepository].
class LoginWithBiometricUseCase {
  const LoginWithBiometricUseCase({required this.repository});

  final AuthRepository repository;

  /// Returns [AuthFailureBiometricUnavailable] early if hardware is missing.
  /// [localizedReason] is displayed in the OS biometric prompt.
  Future<AuthResult> call({required String localizedReason}) async {
    final available = await repository.isBiometricAvailable;
    if (!available) {
      return const AuthFailureBiometricUnavailable();
    }
    return repository.loginWithBiometric(localizedReason: localizedReason);
  }
}
