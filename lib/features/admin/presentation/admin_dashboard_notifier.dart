import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/features/admin/domain/entities/activity_item_entity.dart';
import 'package:deelmarkt/features/admin/domain/entities/admin_stats_entity.dart';
import 'package:deelmarkt/features/admin/domain/usecases/get_admin_activity_usecase.dart';
import 'package:deelmarkt/features/admin/domain/usecases/get_admin_stats_usecase.dart';
import 'package:deelmarkt/features/admin/presentation/admin_providers.dart';

part 'admin_dashboard_notifier.g.dart';

/// Dashboard state: stats + recent activity.
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class AdminDashboardState extends Equatable {
  const AdminDashboardState({required this.stats, required this.activity});

  final AdminStatsEntity stats;
  final List<ActivityItemEntity> activity;

  /// True when all stat counters are zero (nothing requires moderation attention).
  bool get isEmpty =>
      stats.openDisputes == 0 &&
      stats.dsaNoticesWithin24h == 0 &&
      stats.activeListings == 0 &&
      stats.flaggedListings == 0 &&
      stats.reportedUsers == 0;

  @override
  List<Object?> get props => [stats, activity];
}

/// Fetches admin dashboard data (stats + activity) in parallel.
///
/// Presentation → Domain: uses GetAdminStatsUseCase + GetAdminActivityUseCase.
/// Never calls AdminRepository directly (Clean Architecture §1.2).
/// See docs/adr/ADR-002-admin-usecase-layer.md
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
@riverpod
class AdminDashboardNotifier extends _$AdminDashboardNotifier {
  @override
  Future<AdminDashboardState> build() {
    // ref.watch belongs in build() only — subscriptions are tracked correctly.
    final getStats = ref.watch(getAdminStatsUseCaseProvider);
    final getActivity = ref.watch(getAdminActivityUseCaseProvider);
    return _fetchFor(getStats: getStats, getActivity: getActivity);
  }

  /// Core fetch logic — parameterised so both [build] (watch) and [refresh]
  /// (read) can call it without creating duplicate subscriptions.
  Future<AdminDashboardState> _fetchFor({
    required GetAdminStatsUseCase getStats,
    required GetAdminActivityUseCase getActivity,
  }) async {
    final (stats, activity) = await (getStats(), getActivity()).wait;
    return AdminDashboardState(stats: stats, activity: activity);
  }

  /// Pull-to-refresh — shows loading indicator, then fetches fresh data.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _fetchFor(
        getStats: ref.read(getAdminStatsUseCaseProvider),
        getActivity: ref.read(getAdminActivityUseCaseProvider),
      ),
    );
  }
}
