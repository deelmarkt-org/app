import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/admin/domain/entities/admin_stats_entity.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_activity_trends_card.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_empty_hero_card.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_stat_card.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_system_status.dart';

/// Admin-specific empty state shown when no moderation actions are pending.
///
/// Composes the zeroed stat card grid ([_StatCardRow]), the reassuring
/// [AdminEmptyHeroCard] (extracted in P-55), the [AdminActivityTrendsCard]
/// placeholder (extracted in P-55), and the [AdminSystemStatus] sidebar.
/// Together they give admins full situational awareness even when the
/// platform is calm.
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    required this.onRefresh,
    required this.stats,
    this.onViewLogs,
    super.key,
  });

  final VoidCallback onRefresh;
  final VoidCallback? onViewLogs;
  final AdminStatsEntity stats;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'admin.empty.a11y'.tr(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatCardRow(stats: stats),
            const SizedBox(height: Spacing.s6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      AdminEmptyHeroCard(
                        onRefresh: onRefresh,
                        onViewLogs: onViewLogs,
                      ),
                      const SizedBox(height: Spacing.s6),
                      const AdminActivityTrendsCard(),
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.s4),
                const Expanded(child: AdminSystemStatus()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCardRow extends StatelessWidget {
  const _StatCardRow({required this.stats});

  final AdminStatsEntity stats;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.s4,
      runSpacing: Spacing.s4,
      children: [
        AdminStatCard(
          icon: PhosphorIcons.scales(PhosphorIconsStyle.fill),
          count: stats.openDisputes,
          label: 'admin.stats.openDisputes'.tr(),
          iconColor: DeelmarktColors.primary,
          backgroundColor: DeelmarktColors.primarySurface,
        ),
        AdminStatCard(
          icon: PhosphorIcons.warning(PhosphorIconsStyle.fill),
          count: stats.dsaNoticesWithin24h,
          label: 'admin.stats.dsaNotices'.tr(),
          iconColor: DeelmarktColors.error,
          backgroundColor: DeelmarktColors.errorSurface,
        ),
        AdminStatCard(
          icon: PhosphorIcons.flag(PhosphorIconsStyle.fill),
          count: stats.flaggedListings,
          label: 'admin.stats.flaggedListings'.tr(),
          iconColor: DeelmarktColors.warning,
          backgroundColor: DeelmarktColors.warningSurface,
        ),
        AdminStatCard(
          icon: PhosphorIcons.userMinus(PhosphorIconsStyle.fill),
          count: stats.reportedUsers,
          label: 'admin.stats.reportedUsers'.tr(),
          iconColor: DeelmarktColors.neutral500,
          backgroundColor: DeelmarktColors.neutral100,
        ),
      ],
    );
  }
}
