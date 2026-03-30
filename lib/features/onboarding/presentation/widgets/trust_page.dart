import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'trust_feature_card.dart';

/// Page 2 of onboarding — Trust & Security value proposition.
///
/// Layout (from light mobile mockup):
/// Shield icon → Title → Subtitle → 3 feature cards
///
/// Content is identical in light and dark mode (audit resolution #7 —
/// design system overrides mockup content variance).
///
/// Design reference: `docs/screens/01-auth/designs/onboarding_light_mobile_flow/`
class TrustPage extends StatelessWidget {
  const TrustPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
      child: Column(
        children: [
          const SizedBox(height: Spacing.s8),
          Semantics(
            image: true,
            label: 'onboarding.trust_icon_label'.tr(),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(DeelmarktRadius.xxl),
              ),
              child: Icon(
                PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
                size: DeelmarktIconSize.xl,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: Spacing.s6),
          Text(
            'onboarding.safe_buying'.tr(),
            style: theme.textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.s2),
          Text(
            'onboarding.safe_buying_subtitle'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.s8),
          TrustFeatureCard(
            icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.duotone),
            title: 'onboarding.escrow_title'.tr(),
            subtitle: 'onboarding.escrow_subtitle'.tr(),
            iconColor: theme.colorScheme.secondary,
          ),
          const SizedBox(height: Spacing.s4),
          TrustFeatureCard(
            icon: PhosphorIcons.sealCheck(PhosphorIconsStyle.duotone),
            title: 'onboarding.verified_title'.tr(),
            subtitle: 'onboarding.verified_subtitle'.tr(),
            iconColor: theme.colorScheme.primary,
          ),
          const SizedBox(height: Spacing.s4),
          TrustFeatureCard(
            icon: PhosphorIcons.arrowUUpLeft(PhosphorIconsStyle.duotone),
            title: 'onboarding.returns_title'.tr(),
            subtitle: 'onboarding.returns_subtitle'.tr(),
            iconColor: theme.colorScheme.primary,
          ),
          const SizedBox(height: Spacing.s8),
        ],
      ),
    );
  }
}
