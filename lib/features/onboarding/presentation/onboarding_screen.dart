import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/design_system/colors.dart';
import '../../../core/design_system/spacing.dart';

/// Placeholder onboarding screen — Phase 2 (P-14) replaces with full flow.
///
/// Shows language selection + value proposition. Unauthenticated users
/// land here via auth guard redirect.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.s6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIcons.shieldCheck(PhosphorIconsStyle.duotone),
                size: 80,
                color: isDark
                    ? DeelmarktColors.darkPrimary
                    : DeelmarktColors.primary,
                semanticLabel: 'onboarding.trust_icon_label'.tr(),
              ),
              const SizedBox(height: Spacing.s6),
              Text(
                'app.name'.tr(),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? DeelmarktColors.darkPrimary
                      : DeelmarktColors.primary,
                ),
              ),
              const SizedBox(height: Spacing.s3),
              Text(
                'app.tagline'.tr(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark
                      ? DeelmarktColors.darkOnSurfaceSecondary
                      : DeelmarktColors.neutral700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.s8),
              // P-14: Replace with full onboarding flow (language + value prop pages)
              Text(
                'onboarding.placeholder'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? DeelmarktColors.darkOnSurfaceSecondary
                      : DeelmarktColors.neutral500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
