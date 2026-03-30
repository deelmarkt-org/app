import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Page 3 of onboarding — Get Started (CTA).
///
/// Layout (from light mobile mockup):
/// Illustration → Title → Subtitle → "Account aanmaken" CTA → "Ik heb al een account" link
///
/// Design reference: `docs/screens/01-auth/designs/onboarding_light_mobile_flow/`
class GetStartedPage extends StatelessWidget {
  const GetStartedPage({
    required this.onCreateAccount,
    required this.onLogin,
    super.key,
  });

  final VoidCallback onCreateAccount;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: Spacing.s12),
            Semantics(
              image: true,
              label: 'onboarding.handshake_illustration'.tr(),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(DeelmarktRadius.xxl),
                  ),
                  child: Center(
                    child: Icon(
                      PhosphorIcons.handshake(PhosphorIconsStyle.duotone),
                      size: 64,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.s8),
            Text(
              'onboarding.ready_title'.tr(),
              style: theme.textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.s3),
            Text(
              'onboarding.ready_subtitle'.tr(),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.s8),
            DeelButton(
              label: 'onboarding.create_account'.tr(),
              onPressed: onCreateAccount,
              variant: DeelButtonVariant.primary,
              size: DeelButtonSize.large,
            ),
            const SizedBox(height: Spacing.s4),
            DeelButton(
              label: 'onboarding.have_account'.tr(),
              onPressed: onLogin,
              variant: DeelButtonVariant.ghost,
              size: DeelButtonSize.medium,
            ),
            const SizedBox(height: Spacing.s12),
          ],
        ),
      ),
    );
  }
}
