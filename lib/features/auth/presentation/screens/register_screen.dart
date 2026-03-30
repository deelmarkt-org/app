import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/core/utils/validators.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';
import 'package:deelmarkt/widgets/inputs/deel_input.dart';

import 'package:deelmarkt/features/auth/domain/entities/registration_state.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/register_viewmodel.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/otp_input_field.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/registration_form.dart';

/// Multi-step registration screen.
///
/// Single `/register` route with internal step management via [RegisterViewModel].
/// Steps: emailForm → emailVerification → phoneForm → phoneVerification → complete.
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
            state.step != RegistrationStep.emailForm
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed:
                      () =>
                          ref.read(registerViewModelProvider.notifier).goBack(),
                  tooltip: 'nav.back'.tr(),
                )
                : null,
        title: Text(_titleForStep(state.step)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
          child: switch (state.step) {
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
            RegistrationStep.emailVerification => _OtpVerificationView(
              title: 'auth.verify_email_title'.tr(),
              subtitle: 'auth.verify_email_subtitle'.tr(
                namedArgs: {'email': state.email ?? ''},
              ),
              isLoading: state.isLoading,
              errorText: state.errorKey,
              onCompleted:
                  ref.read(registerViewModelProvider.notifier).verifyEmail,
              onResend:
                  () =>
                      ref
                          .read(registerViewModelProvider.notifier)
                          .resendEmailOtp(),
            ),
            RegistrationStep.phoneForm => _PhoneFormView(
              isLoading: state.isLoading,
              errorText: state.errorKey,
              onSubmit:
                  ref.read(registerViewModelProvider.notifier).submitPhone,
            ),
            RegistrationStep.phoneVerification => _OtpVerificationView(
              title: 'auth.verify_phone_title'.tr(),
              subtitle: 'auth.verify_phone_subtitle'.tr(
                namedArgs: {'phone': state.phone ?? ''},
              ),
              isLoading: state.isLoading,
              errorText: state.errorKey,
              onCompleted:
                  ref.read(registerViewModelProvider.notifier).verifyPhone,
              onResend:
                  () => ref
                      .read(registerViewModelProvider.notifier)
                      .submitPhone(state.phone!),
            ),
            RegistrationStep.complete => const SizedBox.shrink(),
          },
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

/// Shared OTP verification view for both email and phone steps.
class _OtpVerificationView extends StatefulWidget {
  const _OtpVerificationView({
    required this.title,
    required this.subtitle,
    required this.onCompleted,
    required this.onResend,
    this.isLoading = false,
    this.errorText,
  });

  final String title;
  final String subtitle;
  final ValueChanged<String> onCompleted;
  final VoidCallback onResend;
  final bool isLoading;
  final String? errorText;

  @override
  State<_OtpVerificationView> createState() => _OtpVerificationViewState();
}

class _OtpVerificationViewState extends State<_OtpVerificationView> {
  int _resendSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _resendSeconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds <= 0) {
        timer.cancel();
        return;
      }
      // H-4: Guard setState with mounted check
      if (mounted) {
        setState(() => _resendSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _resend() {
    widget.onResend();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Spacing.s6),
        Text(widget.title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: Spacing.s2),
        Text(widget.subtitle, style: theme.textTheme.bodyLarge),
        const SizedBox(height: Spacing.s8),
        if (widget.isLoading)
          const Center(child: CircularProgressIndicator.adaptive())
        else
          OtpInputField(
            onCompleted: widget.onCompleted,
            errorText: widget.errorText?.tr(),
            semanticLabel: 'auth.otp_field_label'.tr(),
          ),
        const SizedBox(height: Spacing.s6),
        Center(
          child:
              _resendSeconds > 0
                  ? Text(
                    'auth.otp_resend_timer'.tr(
                      namedArgs: {'seconds': '$_resendSeconds'},
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: DeelmarktColors.neutral500,
                    ),
                  )
                  : DeelButton(
                    label: 'auth.otp_resend'.tr(),
                    variant: DeelButtonVariant.ghost,
                    size: DeelButtonSize.small,
                    fullWidth: false,
                    onPressed: _resend,
                  ),
        ),
      ],
    );
  }
}

/// Phone number entry form with +31 prefix.
class _PhoneFormView extends StatefulWidget {
  const _PhoneFormView({
    required this.onSubmit,
    this.isLoading = false,
    this.errorText,
  });

  final ValueChanged<String> onSubmit;
  final bool isLoading;
  final String? errorText;

  @override
  State<_PhoneFormView> createState() => _PhoneFormViewState();
}

class _PhoneFormViewState extends State<_PhoneFormView> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(_phoneController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Spacing.s6),
          Text(
            'auth.phone_entry_title'.tr(),
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: Spacing.s2),
          Text(
            'auth.phone_entry_subtitle'.tr(),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: Spacing.s6),
          if (widget.errorText != null) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                widget.errorText!.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: DeelmarktColors.error,
                ),
              ),
            ),
            const SizedBox(height: Spacing.s3),
          ],
          DeelInput(
            label: 'form.phone'.tr(),
            hint: '6 12345678',
            controller: _phoneController,
            isRequired: true,
            enabled: !widget.isLoading,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
            validator: Validators.dutchPhone,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(
                left: Spacing.s3,
                right: Spacing.s1,
              ),
              child: Text('+31', style: theme.textTheme.bodyLarge),
            ),
          ),
          const SizedBox(height: Spacing.s6),
          DeelButton(
            label: 'auth.send_code'.tr(),
            onPressed: widget.isLoading ? null : _submit,
            isLoading: widget.isLoading,
          ),
        ],
      ),
    );
  }
}
