import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/admin/domain/entities/admin_stats_entity.dart';
import 'package:deelmarkt/features/admin/presentation/admin_dashboard_notifier.dart';

void main() {
  group('AdminDashboardState', () {
    const stats = AdminStatsEntity(
      openDisputes: 5,
      dsaNoticesWithin24h: 2,
      activeListings: 100,
      escrowAmountCents: 50000,
      flaggedListings: 3,
      reportedUsers: 1,
      approvedCount: 90,
    );

    const emptyStats = AdminStatsEntity(
      openDisputes: 0,
      dsaNoticesWithin24h: 0,
      activeListings: 0,
      escrowAmountCents: 0,
      flaggedListings: 0,
      reportedUsers: 0,
      approvedCount: 0,
    );

    test('isEmpty is false when any moderation counter is non-zero', () {
      const state = AdminDashboardState(stats: stats, activity: []);
      expect(state.isEmpty, isFalse);
    });

    test('isEmpty is true when all moderation counters are zero', () {
      const state = AdminDashboardState(stats: emptyStats, activity: []);
      expect(state.isEmpty, isTrue);
    });

    test('equality based on stats and activity', () {
      const state1 = AdminDashboardState(stats: stats, activity: []);
      const state2 = AdminDashboardState(stats: stats, activity: []);
      expect(state1, equals(state2));
    });

    test('inequality when stats differ', () {
      const state1 = AdminDashboardState(stats: stats, activity: []);
      const state2 = AdminDashboardState(stats: emptyStats, activity: []);
      expect(state1, isNot(equals(state2)));
    });
  });
}
