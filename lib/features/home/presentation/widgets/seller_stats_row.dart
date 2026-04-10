import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/home/domain/entities/seller_stats_entity.dart';

/// Three stat cards for the seller dashboard: total sales, active listings,
/// unread messages.
///
/// Horizontal scroll on compact, wider cards on expanded breakpoint.
///
/// Reference: docs/screens/02-home/designs/seller_mode_home_mobile_light/
class SellerStatsRow extends StatelessWidget {
  const SellerStatsRow({required this.stats, super.key});

  final SellerStatsEntity stats;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
        children: [
          _StatCard(
            icon: PhosphorIcons.currencyEur(PhosphorIconsStyle.fill),
            iconColor: DeelmarktColors.success,
            value: _formatEur(stats.totalSalesCents),
            label: 'home.seller.totalSales'.tr(),
          ),
          const SizedBox(width: Spacing.s3),
          _StatCard(
            icon: PhosphorIcons.package(PhosphorIconsStyle.fill),
            iconColor: DeelmarktColors.secondary,
            value: stats.activeListingsCount.toString(),
            label: 'home.seller.activeListings'.tr(),
          ),
          const SizedBox(width: Spacing.s3),
          _StatCard(
            icon: PhosphorIcons.chatCircle(PhosphorIconsStyle.fill),
            iconColor: DeelmarktColors.primary,
            value: stats.unreadMessagesCount.toString(),
            label: 'home.seller.unreadMessages'.tr(),
            showBadge: stats.unreadMessagesCount > 0,
          ),
        ],
      ),
    );
  }

  static String _formatEur(int cents) {
    final euros = cents / 100;
    return '\u20AC${euros.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.showBadge = false,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? DeelmarktColors.darkSurface : DeelmarktColors.neutral50;
    final textColor =
        isDark ? DeelmarktColors.darkOnSurface : DeelmarktColors.neutral900;
    final labelColor =
        isDark
            ? DeelmarktColors.darkOnSurfaceSecondary
            : DeelmarktColors.neutral500;

    return Semantics(
      label: '$value $label',
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(Spacing.s4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                if (showBadge) ...[
                  const SizedBox(width: Spacing.s1),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: DeelmarktColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: labelColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
