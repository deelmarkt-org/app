import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/validators.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';
import 'package:deelmarkt/widgets/inputs/deel_input.dart';

import 'package:deelmarkt/features/auth/presentation/widgets/password_strength_indicator.dart';

/// Email + password registration form with separate Terms + Privacy acceptance.
///
/// Validates all fields, shows password strength indicator,
/// and requires both Terms and Privacy checkboxes (GDPR Art. 7 compliance).
class RegistrationForm extends StatefulWidget {
  const RegistrationForm({
    required this.onSubmit,
    required this.onLoginTap,
    this.isLoading = false,
    this.errorText,
    super.key,
  });

  final void Function({
    required String email,
    required String password,
    required bool termsAccepted,
    required bool privacyAccepted,
  })
  onSubmit;
  final VoidCallback onLoginTap;
  final bool isLoading;
  final String? errorText;

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _showStrength = false;
  PasswordStrength _strength = PasswordStrength.weak;

  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _termsRecognizer = TapGestureRecognizer()..onTap = _openTerms;
    _privacyRecognizer = TapGestureRecognizer()..onTap = _openPrivacy;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    final pw = _passwordController.text;
    setState(() {
      _showStrength = pw.isNotEmpty;
      _strength = Validators.passwordStrength(pw);
    });
  }

  void _openTerms() {
    launchUrl(Uri.parse('https://deelmarkt.nl/terms'));
  }

  void _openPrivacy() {
    launchUrl(Uri.parse('https://deelmarkt.nl/privacy'));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted || !_privacyAccepted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('validation.terms_required'.tr())));
      return;
    }
    widget.onSubmit(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      termsAccepted: _termsAccepted,
      privacyAccepted: _privacyAccepted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strengthLabels = [
      'password_strength.weak'.tr(),
      'password_strength.fair'.tr(),
      'password_strength.strong'.tr(),
      'password_strength.very_strong'.tr(),
    ];

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: Spacing.s6),
          Text('auth.register'.tr(), style: theme.textTheme.headlineMedium),
          const SizedBox(height: Spacing.s2),
          Text('auth.welcome'.tr(), style: theme.textTheme.bodyLarge),
          SizedBox(height: Spacing.s6),

          // Email
          DeelInput(
            label: 'form.email'.tr(),
            hint: 'email@voorbeeld.nl',
            controller: _emailController,
            focusNode: _emailFocusNode,
            isRequired: true,
            enabled: !widget.isLoading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: Validators.email,
          ),
          SizedBox(height: Spacing.s4),

          // Password
          DeelInput(
            label: 'form.pass_field'.tr(),
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            isRequired: true,
            enabled: !widget.isLoading,
            obscureText: _obscurePassword,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            validator: Validators.password,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed:
                  () => setState(() => _obscurePassword = !_obscurePassword),
              tooltip:
                  _obscurePassword
                      ? 'form.show_password'.tr()
                      : 'form.hide_password'.tr(),
            ),
          ),
          if (_showStrength) ...[
            const SizedBox(height: Spacing.s2),
            PasswordStrengthIndicator(
              strength: _strength,
              labels: strengthLabels,
            ),
          ],
          SizedBox(height: Spacing.s4),

          // Error from server
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

          // Terms checkbox (GDPR Art. 7 — separate consent)
          CheckboxListTile(
            value: _termsAccepted,
            onChanged:
                widget.isLoading
                    ? null
                    : (v) => setState(() => _termsAccepted = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text.rich(
              TextSpan(
                text: 'auth.terms_agree_prefix'.tr(),
                children: [
                  TextSpan(
                    text: 'auth.terms_link'.tr(),
                    style: TextStyle(
                      color: DeelmarktColors.secondary,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: _termsRecognizer,
                  ),
                ],
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),

          // Privacy checkbox (GDPR Art. 7 — separate consent)
          CheckboxListTile(
            value: _privacyAccepted,
            onChanged:
                widget.isLoading
                    ? null
                    : (v) => setState(() => _privacyAccepted = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text.rich(
              TextSpan(
                text: 'auth.privacy_agree_prefix'.tr(),
                children: [
                  TextSpan(
                    text: 'auth.privacy_link'.tr(),
                    style: TextStyle(
                      color: DeelmarktColors.secondary,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: _privacyRecognizer,
                  ),
                ],
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          SizedBox(height: Spacing.s4),

          // Submit
          DeelButton(
            label: 'auth.create_account'.tr(),
            onPressed:
                widget.isLoading || !_termsAccepted || !_privacyAccepted
                    ? null
                    : _submit,
            isLoading: widget.isLoading,
          ),
          const SizedBox(height: Spacing.s3),

          // Login link
          DeelButton(
            label: 'auth.already_have_account'.tr(),
            variant: DeelButtonVariant.ghost,
            onPressed: widget.isLoading ? null : widget.onLoginTap,
          ),
        ],
      ),
    );
  }
}
