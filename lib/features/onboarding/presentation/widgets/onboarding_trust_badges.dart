import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// Trust badges shown in the onboarding footer on expanded breakpoints.
///
/// Three badges: Veilig (Safe), Lokaal (Local), Duurzaam (Sustainable).
/// Only visible when screen width >= 840px (tablet/desktop).
///
/// Design reference: `docs/screens/01-auth/designs/onboarding_tablet_optimized_card/`
class OnboardingTrustBadges extends StatelessWidget {
  const OnboardingTrustBadges({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Breakpoints.isExpanded(context)) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    final style = theme.textTheme.labelSmall?.copyWith(color: color);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Badge(
          icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
          label: 'onboarding.badge_safe'.tr(),
          style: style,
        ),
        const SizedBox(width: Spacing.s6),
        _Badge(
          icon: PhosphorIcons.users(PhosphorIconsStyle.fill),
          label: 'onboarding.badge_local'.tr(),
          style: style,
        ),
        const SizedBox(width: Spacing.s6),
        _Badge(
          icon: PhosphorIcons.leaf(PhosphorIconsStyle.fill),
          label: 'onboarding.badge_sustainable'.tr(),
          style: style,
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, required this.style});

  final IconData icon;
  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: style?.color),
          const SizedBox(width: Spacing.s1),
          Text(label.toUpperCase(), style: style),
        ],
      ),
    );
  }
}
