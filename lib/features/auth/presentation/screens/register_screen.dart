import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';

import 'package:deelmarkt/features/auth/domain/entities/registration_state.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/register_viewmodel.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/otp_verification_view.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/phone_form_view.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/registration_form.dart';

/// Multi-step registration screen.
///
/// Single `/register` route with internal step management via [RegisterViewModel].
/// Steps: emailForm → emailVerification → phoneForm → phoneVerification → complete.
///
/// Reference: docs/screens/01-auth/02-registration.md
class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registerViewModelProvider);

    // H-3: Use ref.listen for navigation side-effect instead of addPostFrameCallback
    ref.listen<RegistrationState>(registerViewModelProvider, (prev, next) {
      if (next.step == RegistrationStep.complete) {
        context.go(AppRoutes.home);
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading:
            state.step == RegistrationStep.emailForm
                ? null
                : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed:
                      () =>
                          ref.read(registerViewModelProvider.notifier).goBack(),
                  tooltip: 'nav.back'.tr(),
                ),
        title: Text(_titleForStep(state.step)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
          child: _StepView(state: state),
        ),
      ),
    );
  }

  String _titleForStep(RegistrationStep step) => switch (step) {
    RegistrationStep.emailForm => 'auth.register'.tr(),
    RegistrationStep.emailVerification => 'auth.verify_email_title'.tr(),
    RegistrationStep.phoneForm => 'auth.phone_entry_title'.tr(),
    RegistrationStep.phoneVerification => 'auth.verify_phone_title'.tr(),
    RegistrationStep.complete => '',
  };
}

class _StepView extends ConsumerWidget {
  const _StepView({required this.state});

  final RegistrationState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (state.step) {
    RegistrationStep.emailForm => RegistrationForm(
      isLoading: state.isLoading,
      errorText: state.errorKey,
      onSubmit:
          ({
            required email,
            required password,
            required termsAccepted,
            required privacyAccepted,
          }) => ref
              .read(registerViewModelProvider.notifier)
              .submitEmail(
                email: email,
                password: password,
                termsAccepted: termsAccepted,
                privacyAccepted: privacyAccepted,
              ),
      onLoginTap: () => context.go(AppRoutes.login),
    ),
    // C-3: Use dedicated resendEmailOtp instead of submitEmail with empty password
    RegistrationStep.emailVerification => OtpVerificationView(
      title: 'auth.verify_email_title'.tr(),
      subtitle: 'auth.verify_email_subtitle'.tr(
        namedArgs: {'email': state.email ?? ''},
      ),
      isLoading: state.isLoading,
      errorText: state.errorKey,
      // Fix #128: wrap tearoffs in lambdas so ref.read is evaluated at call-time,
      // not at build-time. Prevents stale-notifier captures after provider invalidation.
      onCompleted:
          (otp) =>
              ref.read(registerViewModelProvider.notifier).verifyEmail(otp),
      onResend:
          () => ref.read(registerViewModelProvider.notifier).resendEmailOtp(),
    ),
    RegistrationStep.phoneForm => PhoneFormView(
      isLoading: state.isLoading,
      errorText: state.errorKey,
      onSubmit:
          (phone) =>
              ref.read(registerViewModelProvider.notifier).submitPhone(phone),
    ),
    RegistrationStep.phoneVerification => OtpVerificationView(
      title: 'auth.verify_phone_title'.tr(),
      subtitle: 'auth.verify_phone_subtitle'.tr(
        namedArgs: {'phone': state.phone ?? ''},
      ),
      isLoading: state.isLoading,
      errorText: state.errorKey,
      onCompleted:
          (otp) =>
              ref.read(registerViewModelProvider.notifier).verifyPhone(otp),
      onResend:
          () => ref.read(registerViewModelProvider.notifier).resendPhoneOtp(),
    ),
    RegistrationStep.complete => const SizedBox.shrink(),
  };
}
