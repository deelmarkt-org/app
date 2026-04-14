import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/social_login_viewmodel.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Google + Apple sign-in buttons wired to [SocialLoginNotifier].
///
/// Each button shows an independent loading indicator while its OAuth sheet
/// is open. Errors are surfaced via a SnackBar so they don't block the form.
///
/// Reference: docs/screens/01-auth/05-social-login.md
class LoginSocialButtons extends ConsumerWidget {
  const LoginSocialButtons({super.key});

  Future<void> _signIn(
    BuildContext context,
    WidgetRef ref,
    OAuthProvider provider,
  ) async {
    final result = await ref
        .read(socialLoginNotifierProvider.notifier)
        .signIn(provider);

    if (!context.mounted) return;

    switch (result) {
      case AuthSuccess():
        // Navigation is handled by the auth state listener in the router.
        break;
      case AuthFailureOAuthCancelled():
        // User dismissed the sheet — silent, no message needed.
        break;
      case AuthFailureOAuthUnavailable():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('auth.oauthUnavailable'.tr())));
      case AuthFailureNetworkError():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('error.network'.tr())));
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('error.generic'.tr())));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(socialLoginNotifierProvider);

    return Column(
      children: [
        Semantics(
          button: true,
          label: 'auth.continueWithGoogle'.tr(),
          child: DeelButton(
            label: 'auth.continueWithGoogle'.tr(),
            variant: DeelButtonVariant.outline,
            leadingIcon: PhosphorIconsDuotone.googleLogo,
            isLoading: state.loadingProvider == OAuthProvider.google,
            onPressed:
                state.isLoading
                    ? null
                    : () => _signIn(context, ref, OAuthProvider.google),
          ),
        ),
        const SizedBox(height: Spacing.s3),
        Semantics(
          button: true,
          label: 'auth.continueWithApple'.tr(),
          child: DeelButton(
            label: 'auth.continueWithApple'.tr(),
            variant: DeelButtonVariant.outline,
            leadingIcon: PhosphorIconsDuotone.appleLogo,
            isLoading: state.loadingProvider == OAuthProvider.apple,
            onPressed:
                state.isLoading
                    ? null
                    : () => _signIn(context, ref, OAuthProvider.apple),
          ),
        ),
      ],
    );
  }
}
