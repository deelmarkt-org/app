import '../repositories/auth_repository.dart';

/// Resends the email OTP for an existing registration.
class ResendEmailOtpUseCase {
  const ResendEmailOtpUseCase(this._repository);
  final AuthRepository _repository;

  Future<void> call({required String email}) {
    return _repository.resendEmailOtp(email: email);
  }
}
