// TODO(#133): File exceeds 200-line limit (229 lines). Extract sub-widgets.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/admin/domain/entities/admin_stats_entity.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_stat_card.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_system_status.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Admin-specific empty state shown when no moderation actions are pending.
///
/// Displays the zeroed stat card grid, a reassuring hero message,
/// an Activity Trends placeholder, and System Status — giving admins
/// full situational awareness even when the platform is calm.
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
                      _HeroCard(onRefresh: onRefresh, onViewLogs: onViewLogs),
                      const SizedBox(height: Spacing.s6),
                      const _ActivityTrendsCard(),
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onRefresh, required this.onViewLogs});

  final VoidCallback onRefresh;
  final VoidCallback? onViewLogs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.s6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: DeelmarktColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              PhosphorIconsRegular.package,
              size: 36,
              color: DeelmarktColors.primary,
            ),
          ),
          const SizedBox(height: Spacing.s4),
          Text(
            'admin.empty.title'.tr(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: DeelmarktColors.neutral900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.s2),
          Text(
            'admin.empty.subtitle'.tr(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: DeelmarktColors.neutral500),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          ..._buildActions(),
        ],
      ),
    );
  }

  List<Widget> _buildActions() {
    return [
      const SizedBox(height: Spacing.s6),
      DeelButton(
        label: 'admin.empty.refresh'.tr(),
        onPressed: onRefresh,
        size: DeelButtonSize.medium,
        leadingIcon: PhosphorIconsRegular.arrowClockwise,
      ),
      if (onViewLogs != null) ...[
        const SizedBox(height: Spacing.s3),
        Semantics(
          label: 'admin.empty.view_logs'.tr(),
          button: true,
          child: TextButton(
            onPressed: onViewLogs,
            style: TextButton.styleFrom(
              foregroundColor: DeelmarktColors.neutral500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DeelmarktRadius.sm),
              ),
            ),
            child: Text('admin.empty.view_logs'.tr()),
          ),
        ),
      ],
    ];
  }
}

class _ActivityTrendsCard extends StatelessWidget {
  const _ActivityTrendsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.s4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin.empty.trends_title'.tr(),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: DeelmarktColors.neutral900),
          ),
          const SizedBox(height: Spacing.s4),
          Text(
            'admin.empty.trends_empty'.tr(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: DeelmarktColors.neutral300),
          ),
        ],
      ),
    );
  }
}
