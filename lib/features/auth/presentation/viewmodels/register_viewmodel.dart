import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/auth/domain/entities/registration_state.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/auth_providers.dart';

part 'register_viewmodel.g.dart';

const _kGenericErrorKey = 'error.generic';

/// Multi-step registration ViewModel.
/// Steps: emailForm → emailVerification → phoneForm → phoneVerification → complete.
@riverpod
class RegisterViewModel extends _$RegisterViewModel {
  @override
  RegistrationState build() => RegistrationState.initial();

  /// Step 1: Register with email + password + consent timestamps.
  Future<void> submitEmail({
    required String email,
    required String password,
    required bool termsAccepted,
    required bool privacyAccepted,
  }) async {
    state = state.copyWith(isLoading: true, errorKey: () => null);
    try {
      final now = DateTime.now();
      await ref
          .read(registerWithEmailUseCaseProvider)
          .call(
            email: email,
            password: password,
            termsAcceptedAt: now,
            privacyAcceptedAt: now,
          );
      state = state.copyWith(
        step: RegistrationStep.emailVerification,
        email: email,
        isLoading: false,
        termsAccepted: termsAccepted,
        privacyAccepted: privacyAccepted,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorKey: () => e.messageKey);
    } on Exception catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorKey: () => _kGenericErrorKey,
      );
    }
  }

  /// Resend the email OTP without re-triggering full registration.
  Future<void> resendEmailOtp() => _runAction(() async {
    await ref.read(resendEmailOtpUseCaseProvider).call(email: state.email!);
    state = state.copyWith(isLoading: false);
  });

  /// Step 2: Verify email OTP.
  Future<void> verifyEmail(String otp) async {
    state = state.copyWith(isLoading: true, errorKey: () => null);
    try {
      await ref
          .read(verifyEmailOtpUseCaseProvider)
          .call(email: state.email!, token: otp);
      state = state.copyWith(
        step: RegistrationStep.phoneForm,
        isLoading: false,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorKey: () => e.messageKey);
    } on Exception catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorKey: () => _kGenericErrorKey,
      );
    }
  }

  /// Step 3: Submit phone number → sends SMS OTP.
  Future<void> submitPhone(String phone) async {
    state = state.copyWith(isLoading: true, errorKey: () => null);
    try {
      await ref.read(sendPhoneOtpUseCaseProvider).call(phone: phone);
      state = state.copyWith(
        step: RegistrationStep.phoneVerification,
        phone: phone,
        isLoading: false,
      );
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorKey: () => e.messageKey);
    } on Exception catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorKey: () => _kGenericErrorKey,
      );
    }
  }

  /// Step 4: Verify phone OTP → registration complete.
  Future<void> verifyPhone(String otp) async {
    state = state.copyWith(isLoading: true, errorKey: () => null);
    try {
      await ref
          .read(verifyPhoneOtpUseCaseProvider)
          .call(phone: state.phone!, token: otp);
      state = state.copyWith(step: RegistrationStep.complete, isLoading: false);
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorKey: () => e.messageKey);
    } on Exception catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorKey: () => _kGenericErrorKey,
      );
    }
  }

  /// Resend the phone OTP without re-triggering full phone submission.
  Future<void> resendPhoneOtp() async => _runAction(() async {
    await ref.read(sendPhoneOtpUseCaseProvider).call(phone: state.phone!);
    state = state.copyWith(isLoading: false);
  });

  /// Shared error-handling wrapper for simple actions (resend OTP).
  Future<void> _runAction(Future<void> Function() action) async {
    state = state.copyWith(isLoading: true, errorKey: () => null);
    try {
      await action();
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorKey: () => e.messageKey);
    } on Exception catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorKey: () => _kGenericErrorKey,
      );
    }
  }

  /// Navigate back one step in the flow.
  void goBack() {
    final previousStep = switch (state.step) {
      RegistrationStep.emailVerification => RegistrationStep.emailForm,
      RegistrationStep.phoneForm => RegistrationStep.emailVerification,
      RegistrationStep.phoneVerification => RegistrationStep.phoneForm,
      _ => state.step,
    };
    state = state.copyWith(step: previousStep, errorKey: () => null);
  }
}
