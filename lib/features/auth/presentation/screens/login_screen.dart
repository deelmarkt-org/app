import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';
import 'package:deelmarkt/features/auth/presentation/view_models/login_view_model.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/biometric_section.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/login_form.dart';

/// Login screen — email + biometric authentication.
///
/// Route: `/login` (auth guard redirects here when not logged in
/// and onboarding is complete).
///
/// Reference: docs/screens/01-auth/03-login.md
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final FocusNode _passwordFocusNode;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _passwordFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loginViewModelProvider.notifier).init();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    ref.read(loginViewModelProvider.notifier).submitLogin();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // React to auth results
    ref.listen(loginViewModelProvider, (prev, next) {
      final result = next.lastResult;
      if (result == null || result == prev?.lastResult) return;

      switch (result) {
        case AuthSuccess():
          TextInput.finishAutofillContext();
          context.go(AppRoutes.home);
        case AuthFailureInvalidCredentials():
          // Inline error set by ViewModel (passwordError)
          break;
        case AuthFailureNetworkError():
          _showErrorSnackBar('error.network'.tr());
        case AuthFailureRateLimited(:final retryAfter):
          _showErrorSnackBar(
            'auth.errorRateLimited'.tr(args: [retryAfter.inMinutes.toString()]),
          );
        case AuthFailureSessionExpired():
          _showErrorSnackBar('auth.errorSessionExpired'.tr());
        case AuthFailureBiometricFailed():
          _showErrorSnackBar('auth.errorBiometricFailed'.tr());
        case AuthFailureBiometricUnavailable():
        case AuthFailureUnknown():
          _showErrorSnackBar('error.generic'.tr());
      }
    });

    return Scaffold(
      body: SafeArea(
        child: ResponsiveBody(
          maxWidth: 480,
          child: SingleChildScrollView(
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: Spacing.s12),
                  _LogoSection(),
                  const SizedBox(height: Spacing.s8),
                  _WelcomeSection(),
                  const SizedBox(height: Spacing.s8),
                  _SocialLoginButtons(),
                  const SizedBox(height: Spacing.s8),
                  _OrDivider(),
                  const SizedBox(height: Spacing.s8),
                  LoginForm(
                    emailController: _emailController,
                    passwordController: _passwordController,
                    passwordFocusNode: _passwordFocusNode,
                    onSubmit: _submit,
                  ),
                  const SizedBox(height: Spacing.s8),
                  const BiometricSection(),
                  const SizedBox(height: Spacing.s10),
                  _RegisterLink(),
                  const SizedBox(height: Spacing.s12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: DeelmarktColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            PhosphorIconsFill.handshake,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: Spacing.s4),
        Text(
          'DeelMarkt',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: DeelmarktColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'auth.welcomeBack'.tr(),
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: Spacing.s2),
        Text(
          'auth.welcomeSubtitle'.tr(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: DeelmarktColors.neutral500),
        ),
      ],
    );
  }
}

class _SocialLoginButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DeelButton(
          label: 'auth.continueWithGoogle'.tr(),
          variant: DeelButtonVariant.outline,
          leadingIcon: PhosphorIconsDuotone.googleLogo,
          onPressed: null, // Stub — P-44 social login
        ),
        const SizedBox(height: Spacing.s3),
        DeelButton(
          label: 'auth.continueWithApple'.tr(),
          variant: DeelButtonVariant.outline,
          leadingIcon: PhosphorIconsDuotone.appleLogo,
          onPressed: null, // Stub — P-44 social login
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
          child: Text(
            'auth.or'.tr(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: DeelmarktColors.neutral500,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _RegisterLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'auth.newToDeelMarkt'.tr(),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: DeelmarktColors.neutral500),
        ),
        TextButton(
          onPressed: () => context.go(AppRoutes.register),
          child: Text(
            'auth.create_account'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: DeelmarktColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
