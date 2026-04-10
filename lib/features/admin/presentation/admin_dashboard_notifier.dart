import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/admin/domain/entities/activity_item_entity.dart';
import 'package:deelmarkt/features/admin/domain/entities/admin_stats_entity.dart';

part 'admin_dashboard_notifier.g.dart';

/// Dashboard state: stats + recent activity.
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class AdminDashboardState extends Equatable {
  const AdminDashboardState({required this.stats, required this.activity});

  final AdminStatsEntity stats;
  final List<ActivityItemEntity> activity;

  /// True when all stat counters are zero.
  bool get isEmpty =>
      stats.openDisputes == 0 &&
      stats.dsaNoticesWithin24h == 0 &&
      stats.flaggedListings == 0 &&
      stats.reportedUsers == 0;

  @override
  List<Object?> get props => [stats, activity];
}

/// Fetches admin dashboard data (stats + activity) in parallel.
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
@riverpod
class AdminDashboardNotifier extends _$AdminDashboardNotifier {
  @override
  Future<AdminDashboardState> build() async {
    final repo = ref.watch(adminRepositoryProvider);

    final (stats, activity) =
        await (repo.getStats(), repo.getRecentActivity()).wait;

    return AdminDashboardState(stats: stats, activity: activity);
  }

  /// Pull-to-refresh — invalidates and refetches.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
