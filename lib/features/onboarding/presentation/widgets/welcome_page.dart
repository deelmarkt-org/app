import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/settings/language_switch.dart';

/// Page 1 of onboarding — Welcome + Language selection.
///
/// Layout (from light mobile mockup):
/// Logo → Tagline → Subtitle → Illustration placeholder → LanguageSwitch
///
/// Design reference: `docs/screens/01-auth/designs/onboarding_light_mobile_flow/`
/// Page 1 (lines 130-168).
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: Spacing.s12),
            Text(
              'app.name'.tr(),
              style: theme.textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: Spacing.s3),
            Text(
              'onboarding.tagline'.tr(),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.s8),
            _IllustrationPlaceholder(
              icon: PhosphorIcons.storefront(PhosphorIconsStyle.duotone),
              semanticLabel: 'onboarding.welcome_illustration'.tr(),
              backgroundColor:
                  isDark
                      ? DeelmarktColors.darkSurfaceElevated
                      : DeelmarktColors.primarySurface,
              iconColor: theme.colorScheme.primary,
            ),
            const SizedBox(height: Spacing.s8),
            Text(
              'onboarding.subtitle'.tr(),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.s8),
            const LanguageSwitch(),
            const SizedBox(height: Spacing.s12),
          ],
        ),
      ),
    );
  }
}

/// Placeholder for onboarding illustrations.
///
/// Renders a Phosphor icon in a tinted container. Will be replaced by
/// real SVG illustrations in a future design asset task.
class _IllustrationPlaceholder extends StatelessWidget {
  const _IllustrationPlaceholder({
    required this.icon,
    required this.semanticLabel,
    required this.backgroundColor,
    required this.iconColor,
  });

  final IconData icon;
  final String semanticLabel;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(DeelmarktRadius.xxl),
          ),
          child: Center(child: Icon(icon, size: 64, color: iconColor)),
        ),
      ),
    );
  }
}
