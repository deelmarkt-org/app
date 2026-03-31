import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

import 'package:deelmarkt/features/auth/presentation/widgets/otp_input_field.dart';

/// Shared OTP verification view for both email and phone steps.
class OtpVerificationView extends StatefulWidget {
  const OtpVerificationView({
    required this.title,
    required this.subtitle,
    required this.onCompleted,
    required this.onResend,
    this.isLoading = false,
    this.errorText,
    super.key,
  });

  final String title;
  final String subtitle;
  final ValueChanged<String> onCompleted;
  final VoidCallback onResend;
  final bool isLoading;
  final String? errorText;

  @override
  State<OtpVerificationView> createState() => _OtpVerificationViewState();
}

class _OtpVerificationViewState extends State<OtpVerificationView> {
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
