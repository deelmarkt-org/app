import '../repositories/auth_repository.dart';

/// Verifies the phone OTP code sent via SMS.
class VerifyPhoneOtpUseCase {
  const VerifyPhoneOtpUseCase(this._repository);
  final AuthRepository _repository;

  Future<void> call({required String phone, required String token}) {
    return _repository.verifyPhoneOtp(phone: phone, token: token);
  }
}
