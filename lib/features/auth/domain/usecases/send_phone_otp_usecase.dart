import 'package:deelmarkt/core/utils/validators.dart';
import 'package:deelmarkt/features/auth/domain/repositories/auth_repository.dart';

/// Normalizes the phone number to E.164 and sends an SMS OTP.
class SendPhoneOtpUseCase {
  const SendPhoneOtpUseCase(this._repository);
  final AuthRepository _repository;

  Future<void> call({required String phone}) {
    final normalized = Validators.normalizePhone(phone);
    return _repository.sendPhoneOtp(phone: normalized);
  }
}
