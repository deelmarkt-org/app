import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/router/routes.dart';

/// "New to DeelMarkt? Create account" link at bottom of login screen.
///
/// Uses [colorScheme.secondary] for link text to meet WCAG 2.2 AA
/// contrast at bodyMedium (14px) size — primary orange fails at 3.4:1.
/// Reference: docs/screens/01-auth/03-login.md
class LoginRegisterLink extends StatelessWidget {
  const LoginRegisterLink({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor =
        isDark
            ? DeelmarktColors.darkOnSurfaceSecondary
            : DeelmarktColors.neutral700;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'auth.newToDeelMarkt'.tr(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: secondaryTextColor,
          ),
        ),
        TextButton(
          onPressed: () => context.go(AppRoutes.register),
          child: Text(
            'auth.create_account'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
