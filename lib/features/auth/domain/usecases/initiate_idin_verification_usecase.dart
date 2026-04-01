import 'package:deelmarkt/features/auth/domain/repositories/auth_repository.dart';

/// Initiates iDIN bank verification and returns the redirect URL.
class InitiateIdinVerificationUseCase {
  const InitiateIdinVerificationUseCase(this._repository);
  final AuthRepository _repository;

  Future<String> call() {
    return _repository.initiateIdinVerification();
  }
}
