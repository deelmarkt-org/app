import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';
import 'package:deelmarkt/widgets/inputs/deel_input.dart';
import 'package:deelmarkt/features/auth/presentation/view_models/login_view_model.dart';

/// Email + password form with forgot-password link and submit button.
///
/// Must be wrapped in an [AutofillGroup] by the parent screen.
///
/// Uses [colorScheme.secondary] for the forgot-password link to meet
/// WCAG 2.2 AA contrast at [bodySmall] (12px) size — primary orange
/// only passes for large text (>= 18.66px bold).
/// Reference: docs/screens/01-auth/03-login.md
class LoginForm extends ConsumerWidget {
  const LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.passwordFocusNode,
    required this.onSubmit,
    super.key,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode passwordFocusNode;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginViewModelProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DeelInput(
          label: 'form.email'.tr(),
          hint: 'naam@voorbeeld.nl',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          errorText: state.emailError?.tr(),
          controller: emailController,
          onChanged:
              (v) => ref.read(loginViewModelProvider.notifier).setEmail(v),
          enabled: !state.isLoading,
        ),
        const SizedBox(height: Spacing.s5),
        DeelInput(
          label: 'form.pass_field'.tr(),
          hint: '••••••••',
          obscureText: state.obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          errorText: state.passwordError?.tr(),
          controller: passwordController,
          focusNode: passwordFocusNode,
          onChanged:
              (v) => ref.read(loginViewModelProvider.notifier).setPassword(v),
          onFieldSubmitted: (_) => onSubmit(),
          enabled: !state.isLoading,
          suffixIcon: Semantics(
            label:
                state.obscurePassword
                    ? 'form.show_password'.tr()
                    : 'form.hide_password'.tr(),
            child: IconButton(
              icon: Icon(
                state.obscurePassword
                    ? PhosphorIconsDuotone.eye
                    : PhosphorIconsDuotone.eyeSlash,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed:
                  () =>
                      ref
                          .read(loginViewModelProvider.notifier)
                          .togglePasswordVisibility(),
            ),
          ),
        ),
        const SizedBox(height: Spacing.s1),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('auth.forgotPasswordComingSoon'.tr())),
              );
            },
            child: Text(
              'auth.forgotPassword'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: Spacing.s4),
        DeelButton(
          label: 'auth.logIn'.tr(),
          isLoading: state.isLoading,
          onPressed: state.isLoading ? null : onSubmit,
        ),
      ],
    );
  }
}
