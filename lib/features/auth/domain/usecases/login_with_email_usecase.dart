import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';
import 'package:deelmarkt/features/auth/domain/repositories/auth_repository.dart';

/// Normalises email and delegates to [AuthRepository].
///
/// Validation (email format, password length) is a presentation concern
/// handled by the ViewModel before this use case is invoked.
class LoginWithEmailUseCase {
  const LoginWithEmailUseCase({required this.repository});

  final AuthRepository repository;

  /// Normalises [email] (trim + lowercase) and delegates to the repository.
  Future<AuthResult> call({required String email, required String password}) {
    final normalised = email.trim().toLowerCase();
    return repository.loginWithEmail(email: normalised, password: password);
  }
}
