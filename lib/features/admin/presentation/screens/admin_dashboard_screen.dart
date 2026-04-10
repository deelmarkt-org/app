import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/admin/presentation/admin_dashboard_notifier.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_activity_feed.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_empty_state.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_loading_skeleton.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_sla_bar.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_stat_card.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_system_status.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';

/// Admin dashboard — overview of moderation queues and platform health.
///
/// Composes stat cards, SLA bar, activity feed, and system status
/// from [AdminDashboardNotifier] state.
///
final _thousandsFormat = NumberFormat('#,##0', 'nl_NL');

/// Reference: docs/screens/08-admin/designs/admin_dashboard_main_view/
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDashboardNotifierProvider);

    return state.when(
      loading: () => const AdminLoadingSkeleton(),
      error:
          (_, _) => ErrorState(
            onRetry:
                () =>
                    ref.read(adminDashboardNotifierProvider.notifier).refresh(),
          ),
      data: (data) {
        if (data.isEmpty) {
          return AdminEmptyState(
            onRefresh:
                () =>
                    ref.read(adminDashboardNotifierProvider.notifier).refresh(),
          );
        }
        return _DataView(data: data);
      },
    );
  }
}

class _DataView extends StatelessWidget {
  const _DataView({required this.data});

  final AdminDashboardState data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context),
          const SizedBox(height: Spacing.s6),
          _statCards(),
          const SizedBox(height: Spacing.s6),
          _slaAndActivity(),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'admin.dashboard.title'.tr(),
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: Spacing.s2),
        Text(
          'admin.dashboard.subtitle'.tr(),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: DeelmarktColors.neutral500),
        ),
      ],
    );
  }

  Widget _statCards() {
    final stats = data.stats;
    final escrowWhole = stats.escrowAmountCents ~/ 100;
    final escrowFormatted = '\u20AC${_thousandsFormat.format(escrowWhole)}';

    return Wrap(
      spacing: Spacing.s4,
      runSpacing: Spacing.s4,
      children: [
        AdminStatCard(
          icon: PhosphorIcons.scales(PhosphorIconsStyle.fill),
          count: stats.openDisputes,
          label: 'admin.stats.openDisputes'.tr(),
          badgeText: 'admin.badge.today'.tr(args: ['+2']),
          badgeColor: DeelmarktColors.primary,
          iconColor: DeelmarktColors.primary,
          backgroundColor: DeelmarktColors.primarySurface,
        ),
        AdminStatCard(
          icon: PhosphorIcons.warning(PhosphorIconsStyle.fill),
          count: stats.dsaNoticesWithin24h,
          label: 'admin.stats.dsaNotices'.tr(),
          badgeText: 'admin.badge.critical'.tr(),
          badgeColor: DeelmarktColors.error,
          iconColor: DeelmarktColors.error,
          backgroundColor: DeelmarktColors.errorSurface,
        ),
        AdminStatCard(
          icon: PhosphorIcons.lockSimple(PhosphorIconsStyle.fill),
          count: stats.activeListings,
          label: 'admin.stats.activeListings'.tr(),
          badgeText: 'admin.badge.normal'.tr(),
          badgeColor: DeelmarktColors.info,
          iconColor: DeelmarktColors.info,
          backgroundColor: DeelmarktColors.infoSurface,
        ),
        AdminStatCard(
          icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.fill),
          countText: escrowFormatted,
          count: 0,
          label: 'admin.stats.escrow'.tr(),
          badgeText: 'admin.badge.safe'.tr(),
          badgeColor: DeelmarktColors.success,
          iconColor: DeelmarktColors.success,
          backgroundColor: DeelmarktColors.successSurface,
        ),
      ],
    );
  }

  // Placeholder SLA total used when no DSA notices are open (Phase A).
  static const int _slaFallbackTotal = 3;
  // Placeholder SLA completion rate for Phase A mock data.
  static const double _slaFallbackCompletion = 0.66;

  Widget _slaAndActivity() {
    final stats = data.stats;
    final slaTotal =
        stats.dsaNoticesWithin24h > 0
            ? stats.dsaNoticesWithin24h
            : _slaFallbackTotal;
    final slaCompleted = (slaTotal * _slaFallbackCompletion).round();
    final slaProgress = slaTotal > 0 ? slaCompleted / slaTotal : 1.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              AdminSlaBar(
                progress: slaProgress,
                completed: slaCompleted,
                total: slaTotal,
              ),
              const SizedBox(height: Spacing.s6),
              AdminActivityFeed(items: data.activity),
            ],
          ),
        ),
        const SizedBox(width: Spacing.s4),
        const Expanded(child: AdminSystemStatus()),
      ],
    );
  }
}
