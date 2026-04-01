import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// "Welcome back" heading + subtitle.
///
/// Uses [DeelmarktColors.neutral700] in light mode for subtitle to meet
/// WCAG 2.2 AA contrast requirements at bodyMedium (14px) size.
/// Reference: docs/screens/01-auth/03-login.md
class LoginWelcomeSection extends StatelessWidget {
  const LoginWelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor =
        isDark
            ? DeelmarktColors.darkOnSurfaceSecondary
            : DeelmarktColors.neutral700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'auth.welcomeBack'.tr(),
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: Spacing.s2),
        Text(
          'auth.welcomeSubtitle'.tr(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: secondaryTextColor,
          ),
        ),
      ],
    );
  }
}
