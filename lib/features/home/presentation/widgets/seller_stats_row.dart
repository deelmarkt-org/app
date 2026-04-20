import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/features/home/domain/entities/seller_stats_entity.dart';
import 'package:deelmarkt/widgets/cards/stat_card.dart';

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
          StatCard(
            icon: PhosphorIcons.trendUp(PhosphorIconsStyle.fill),
            iconColor: DeelmarktColors.success,
            value: Formatters.euroFromCents(stats.totalSalesCents),
            label: 'home.seller.totalSales'.tr(),
          ),
          const SizedBox(width: Spacing.s3),
          StatCard(
            icon: PhosphorIcons.package(PhosphorIconsStyle.fill),
            iconColor: DeelmarktColors.secondary,
            value: stats.activeListingsCount.toString(),
            label: 'home.seller.activeListings'.tr(),
          ),
          const SizedBox(width: Spacing.s3),
          StatCard(
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
}
