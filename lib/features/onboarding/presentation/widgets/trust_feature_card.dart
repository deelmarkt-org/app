import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// Rounded feature card used on the Trust page (Page 2) of onboarding.
///
/// Layout: icon container (40x40) + title/subtitle column.
/// Informational only — no interaction, no touch target requirement.
/// Wrapped in [Semantics] for screen reader accessibility (EAA compliance).
///
/// Design reference: `docs/screens/01-auth/designs/onboarding_light_mobile_flow/`
/// Page 2 feature rows (lines 196-225).
class TrustFeatureCard extends StatelessWidget {
  const TrustFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$title — $subtitle',
      child: Container(
        padding: const EdgeInsets.all(Spacing.s5),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
              ),
              child: Icon(icon, color: iconColor, size: DeelmarktIconSize.md),
            ),
            const SizedBox(width: Spacing.s5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: Spacing.s1),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
