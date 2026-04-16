import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';
import 'package:deelmarkt/features/auth/presentation/view_models/login_view_model.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/biometric_section.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/login_form.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/login_logo_section.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/login_or_divider.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/login_register_link.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/login_social_buttons.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/login_welcome_section.dart';

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

  void _handleAuthResult(AuthResult result) {
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
      case AuthFailureOAuthCancelled():
      case AuthFailureOAuthUnavailable():
        // Handled by LoginSocialButtons — never emitted by loginViewModelProvider.
        break;
    }
  }

  Widget _buildContent() {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Spacing.s12),
          const LoginLogoSection(),
          const SizedBox(height: Spacing.s8),
          const LoginWelcomeSection(),
          const SizedBox(height: Spacing.s8),
          const LoginSocialButtons(),
          const SizedBox(height: Spacing.s8),
          const LoginOrDivider(),
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
          const LoginRegisterLink(),
          const SizedBox(height: Spacing.s12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(loginViewModelProvider, (prev, next) {
      final result = next.lastResult;
      if (result == null || result == prev?.lastResult) return;
      _handleAuthResult(result);
    });

    final isExpanded = Breakpoints.isExpanded(context);
    final theme = Theme.of(context);
    Widget content = _buildContent();

    // Wrap in elevated card on expanded (tablet/desktop) layouts.
    if (isExpanded) {
      content = Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
          side: BorderSide(color: theme.dividerColor),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.s8,
            vertical: Spacing.s4,
          ),
          child: content,
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ResponsiveBody(
          maxWidth: 480,
          child: SingleChildScrollView(child: content),
        ),
      ),
    );
  }
}
