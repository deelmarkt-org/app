import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

/// Reusable stat-display card for dashboard rows.
///
/// Renders an icon + value + label inside a tinted container and supports
/// an optional orange notification dot next to the icon. Width is fixed to
/// [StatCard.width] so multiple cards can be laid out in a horizontal scroll
/// without breakpoint math, and so skeleton placeholders can mirror the
/// final dimensions without drift.
///
/// Promoted from the former private `_StatCard` in
/// `lib/features/home/presentation/widgets/seller_stats_row.dart` so other
/// dashboards can share the same look without cross-feature imports.
///
/// Reference: docs/screens/02-home/02-home-seller.md
class StatCard extends StatelessWidget {
  const StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.showBadge = false,
    super.key,
  });

  /// Fixed card width — kept as a public constant so skeleton placeholders
  /// (e.g. in [SellerHomeLoadingView]) can reference the same value.
  static const double width = 140;

  /// Diameter of the optional orange unread-indicator dot.
  static const double _badgeDotSize = 8;

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final palette = _StatCardPalette.of(context);
    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(Spacing.s4),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _iconRow(),
            const Spacer(),
            _valueText(context, palette.value),
            _labelText(context, palette.label),
          ],
        ),
      ),
    );
  }

  Widget _iconRow() {
    return Row(
      children: [
        Icon(icon, size: DeelmarktIconSize.sm, color: iconColor),
        if (showBadge) ...[
          const SizedBox(width: Spacing.s1),
          Container(
            key: const Key('stat_card_badge'),
            width: _badgeDotSize,
            height: _badgeDotSize,
            decoration: const BoxDecoration(
              color: DeelmarktColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }

  Widget _valueText(BuildContext context, Color color) {
    return Text(
      value,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }

  Widget _labelText(BuildContext context, Color color) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Theme-aware colour triple for the StatCard container + text.
class _StatCardPalette {
  const _StatCardPalette({
    required this.background,
    required this.value,
    required this.label,
  });

  final Color background;
  final Color value;
  final Color label;

  factory _StatCardPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _StatCardPalette(
      background:
          isDark ? DeelmarktColors.darkSurface : DeelmarktColors.neutral50,
      value:
          isDark ? DeelmarktColors.darkOnSurface : DeelmarktColors.neutral900,
      label:
          isDark
              ? DeelmarktColors.darkOnSurfaceSecondary
              : DeelmarktColors.neutral500,
    );
  }
}
