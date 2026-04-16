import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/social_login_viewmodel.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Google + Apple sign-in buttons wired to [SocialLoginNotifier].
///
/// Each button shows an independent loading indicator while its OAuth sheet
/// is open. Errors are surfaced via a SnackBar so they don't block the form.
///
/// Apple button uses a filled-black style per Apple HIG §Sign in with Apple.
/// Google button uses the Material-compliant outline variant from DeelButton.
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
      case AuthFailureOAuthCancelled():
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
        _AppleSignInButton(
          isLoading: state.loadingProvider == OAuthProvider.apple,
          onPressed:
              state.isLoading
                  ? null
                  : () => _signIn(context, ref, OAuthProvider.apple),
        ),
      ],
    );
  }
}

/// Apple HIG-compliant filled-black button with white Apple logo + text.
/// 52 px min height satisfies CLAUDE.md §10 (≥44×44 touch target).
class _AppleSignInButton extends StatelessWidget {
  const _AppleSignInButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final label = 'auth.continueWithApple'.tr();
    // Apple HIG: dark mode requires white background + black foreground.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? DeelmarktColors.white : DeelmarktColors.neutral900;
    final fgColor = isDark ? DeelmarktColors.neutral900 : DeelmarktColors.white;
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: fgColor,
            disabledBackgroundColor: bgColor.withValues(alpha: 0.5),
            disabledForegroundColor: fgColor.withValues(alpha: 0.8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DeelmarktRadius.md),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          child:
              isLoading
                  ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        fgColor.withValues(alpha: 0.8),
                      ),
                    ),
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(PhosphorIconsFill.appleLogo, size: 20),
                      const SizedBox(width: Spacing.s2),
                      Flexible(
                        child: Text(label, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
