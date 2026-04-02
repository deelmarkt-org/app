import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/deel_badge_theme.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/badges/deel_badge_data.dart';
import 'package:deelmarkt/widgets/badges/deel_badge_tokens.dart';

/// Size variants for [DeelBadge].
enum DeelBadgeSize { small, medium }

/// A single verification badge with icon, colour, and optional tooltip.
///
/// Renders as a small coloured circle with a Phosphor duotone icon.
/// Verified badges use type-specific colours; unverified badges use neutral.
///
/// Reference: docs/design-system/components.md §Badges
class DeelBadge extends StatelessWidget {
  const DeelBadge({
    required this.type,
    this.size = DeelBadgeSize.medium,
    this.isVerified = true,
    this.showTooltip = true,
    super.key,
  });

  final DeelBadgeType type;
  final DeelBadgeSize size;
  final bool isVerified;
  final bool showTooltip;

  double get _iconSize => switch (size) {
    DeelBadgeSize.small => DeelBadgeTokens.iconSmall,
    DeelBadgeSize.medium => DeelBadgeTokens.iconMedium,
  };

  double get _containerSize => switch (size) {
    DeelBadgeSize.small => DeelBadgeTokens.containerSmall,
    DeelBadgeSize.medium => DeelBadgeTokens.containerMedium,
  };

  @override
  Widget build(BuildContext context) {
    final badgeTheme =
        Theme.of(context).extension<DeelBadgeThemeData>() ??
        DeelBadgeThemeData.light();
    final config = resolveConfig(type);
    final color =
        isVerified ? config.colorResolver(badgeTheme) : badgeTheme.unverified;
    final background =
        isVerified
            ? config.backgroundResolver(badgeTheme)
            : badgeTheme.unverifiedBackground;

    final badge = Semantics(
      label: config.labelKey.tr(),
      child: Container(
        width: _containerSize,
        height: _containerSize,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Center(child: Icon(config.icon, size: _iconSize, color: color)),
      ),
    );

    if (!showTooltip) return badge;

    return Tooltip(
      message: config.tooltipKey.tr(),
      preferBelow: true,
      decoration: BoxDecoration(
        color: badgeTheme.tooltipBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: badgeTheme.tooltipForeground),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: DeelBadgeTokens.minTapTarget,
          minHeight: DeelBadgeTokens.minTapTarget,
        ),
        child: Center(child: badge),
      ),
    );
  }
}

/// A horizontal row of badges with a max-visible constraint.
///
/// Shows up to [maxVisible] badges inline. If more badges exist,
/// displays a "+N" overflow indicator.
class DeelBadgeRow extends StatelessWidget {
  const DeelBadgeRow({
    required this.badges,
    this.maxVisible = 3,
    this.size = DeelBadgeSize.medium,
    super.key,
  });

  final List<DeelBadgeType> badges;
  final int maxVisible;
  final DeelBadgeSize size;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();

    final visible = badges.take(maxVisible).toList();
    final overflow = badges.length - maxVisible;
    final badgeTheme =
        Theme.of(context).extension<DeelBadgeThemeData>() ??
        DeelBadgeThemeData.light();

    return Semantics(
      label: 'badge.row'.tr(args: [badges.length.toString()]),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < visible.length; i++) ...[
            if (i > 0) const SizedBox(width: Spacing.s1),
            DeelBadge(type: visible[i], size: size),
          ],
          if (overflow > 0) ...[
            const SizedBox(width: Spacing.s1),
            Container(
              constraints: const BoxConstraints(
                minWidth: DeelBadgeTokens.minTapTarget,
                minHeight: DeelBadgeTokens.minTapTarget,
              ),
              alignment: Alignment.center,
              child: Text(
                '+$overflow',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: DeelBadgeTokens.overflowFontSize,
                  fontWeight: FontWeight.w600,
                  color: badgeTheme.unverified,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
