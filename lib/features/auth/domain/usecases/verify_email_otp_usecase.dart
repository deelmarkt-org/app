import 'package:deelmarkt/features/auth/domain/repositories/auth_repository.dart';

/// Verifies the email OTP code sent during registration.
class VerifyEmailOtpUseCase {
  const VerifyEmailOtpUseCase(this._repository);
  final AuthRepository _repository;

  Future<void> call({required String email, required String token}) {
    return _repository.verifyEmailOtp(email: email, token: token);
  }
}
