import '../repositories/auth_repository.dart';

/// Registers a new user with email, password, and consent timestamps.
class RegisterWithEmailUseCase {
  const RegisterWithEmailUseCase(this._repository);
  final AuthRepository _repository;

  Future<void> call({
    required String email,
    required String password,
    required DateTime termsAcceptedAt,
    required DateTime privacyAcceptedAt,
  }) {
    return _repository.registerWithEmail(
      email: email,
      password: password,
      termsAcceptedAt: termsAcceptedAt,
      privacyAcceptedAt: privacyAcceptedAt,
    );
  }
}
