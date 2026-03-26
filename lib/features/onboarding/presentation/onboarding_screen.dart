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
                color: DeelmarktColors.primary,
              ),
              const SizedBox(height: Spacing.s6),
              Text(
                'DeelMarkt',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: DeelmarktColors.primary,
                ),
              ),
              const SizedBox(height: Spacing.s3),
              Text(
                'app.tagline'.tr(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: DeelmarktColors.neutral700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.s8),
              // P-14: Replace with full onboarding flow (language + value prop pages)
              Text(
                'Onboarding — coming in Phase 2',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DeelmarktColors.neutral500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
