import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/design_system/typography.dart';

/// Reusable stat card for the admin dashboard overview grid.
///
/// Displays a metric icon with optional badge, a large count, and a label.
/// Uses a light card background with a subtle border.
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    required this.icon,
    required this.count,
    required this.label,
    this.countText,
    this.badgeText,
    this.badgeColor,
    this.iconColor,
    this.backgroundColor,
    super.key,
  });

  /// Phosphor icon representing the stat category.
  final IconData icon;

  /// Numeric value to display prominently.
  final int count;

  /// Optional formatted text override for the count (e.g. "€12.450").
  /// When provided, this is displayed instead of [count].
  final String? countText;

  /// Short description label below the count.
  final String label;

  /// Optional badge text (e.g. "+2 vandaag", "Kritiek").
  final String? badgeText;

  /// Badge background colour. Defaults to [DeelmarktColors.primarySurface].
  final Color? badgeColor;

  /// Icon colour. Defaults to [DeelmarktColors.primary].
  final Color? iconColor;

  /// Card background colour. Defaults to [DeelmarktColors.white].
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: ${countText ?? '$count'}',
      child: Container(
        padding: const EdgeInsets.all(Spacing.s4),
        decoration: BoxDecoration(
          color: backgroundColor ?? Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIconRow(context),
            const SizedBox(height: Spacing.s3),
            _buildCount(context),
            const SizedBox(height: Spacing.s1),
            _buildLabel(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIconRow(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(Spacing.s2),
          decoration: BoxDecoration(
            color: (iconColor ?? DeelmarktColors.primary).withValues(
              alpha: 0.1,
            ),
            borderRadius: BorderRadius.circular(DeelmarktRadius.sm),
          ),
          child: Icon(
            icon,
            size: 20,
            color: iconColor ?? DeelmarktColors.primary,
          ),
        ),
        if (badgeText != null) ...[
          const SizedBox(width: Spacing.s2),
          _buildBadge(context),
        ],
      ],
    );
  }

  Widget _buildBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s2,
        vertical: Spacing.s1,
      ),
      decoration: BoxDecoration(
        color: badgeColor ?? DeelmarktColors.primarySurface,
        borderRadius: BorderRadius.circular(DeelmarktRadius.full),
      ),
      child: Text(
        badgeText!,
        style: Theme.of(
          context,
        ).textTheme.labelSmall!.copyWith(color: _badgeTextColor()),
      ),
    );
  }

  Color _badgeTextColor() {
    // Surface colours (light bg) → use the matching saturated text colour.
    if (badgeColor == DeelmarktColors.errorSurface) {
      return DeelmarktColors.error;
    }
    if (badgeColor == DeelmarktColors.warningSurface) {
      return DeelmarktColors.warning;
    }
    if (badgeColor == DeelmarktColors.successSurface) {
      return DeelmarktColors.success;
    }
    if (badgeColor == DeelmarktColors.primarySurface) {
      return DeelmarktColors.primary;
    }
    // Saturated base colours (primary, error, success, info, warning) used as
    // badge backgrounds need white text to meet WCAG AA contrast requirements.
    if (badgeColor == DeelmarktColors.error ||
        badgeColor == DeelmarktColors.success ||
        badgeColor == DeelmarktColors.info ||
        badgeColor == DeelmarktColors.warning ||
        badgeColor == DeelmarktColors.primary) {
      return DeelmarktColors.white;
    }
    return DeelmarktColors.primary;
  }

  Widget _buildCount(BuildContext context) {
    return Text(
      countText ?? '$count',
      style: DeelmarktTypography.statCount.copyWith(
        color: DeelmarktColors.neutral900,
      ),
    );
  }

  Widget _buildLabel(BuildContext context) {
    return Text(
      label,
      style: DeelmarktTypography.statLabel.copyWith(
        color: DeelmarktColors.neutral500,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
