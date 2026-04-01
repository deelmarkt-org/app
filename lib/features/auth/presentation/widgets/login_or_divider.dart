import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// "of" / "or" divider between social login and email form.
///
/// Uses design system [labelSmall] letter spacing (0.88) — no custom overrides.
/// Reference: docs/screens/01-auth/03-login.md
class LoginOrDivider extends StatelessWidget {
  const LoginOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor =
        isDark
            ? DeelmarktColors.darkOnSurfaceSecondary
            : DeelmarktColors.neutral700;

    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
          child: Text(
            'auth.or'.tr(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: secondaryTextColor,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
