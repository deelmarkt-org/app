import 'package:flutter/foundation.dart';

import 'package:deelmarkt/features/admin/domain/entities/activity_item_entity.dart';
import 'package:deelmarkt/features/admin/domain/entities/admin_stats_entity.dart';
import 'package:deelmarkt/features/admin/domain/repositories/admin_repository.dart';

/// In-memory mock for development when Supabase admin RPCs aren't ready.
///
/// Returns hardcoded sample data matching the design after a simulated
/// network delay. Toggle via provider override in dev builds (ADR-MOCK-SWAP).
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class MockAdminRepository implements AdminRepository {
  MockAdminRepository() {
    if (kReleaseMode) {
      throw StateError('MockAdminRepository cannot be used in release builds');
    }
  }

  @override
  Future<AdminStatsEntity> getStats() async {
    await _simulateDelay();
    return const AdminStatsEntity(
      openDisputes: 12,
      dsaNoticesWithin24h: 3,
      activeListings: 156,
      escrowAmountCents: 1245000,
      flaggedListings: 8,
      reportedUsers: 4,
      approvedCount: 142,
    );
  }

  // Fixed reference time for deterministic mock data — avoids flaky tests.
  static final _mockNow = DateTime(2026, 4, 10, 9);

  @override
  // ignore: avoid_redundant_argument_values
  Future<List<ActivityItemEntity>> getRecentActivity({int limit = 10}) async {
    await _simulateDelay();
    final now = _mockNow;
    return [
      ActivityItemEntity(
        id: 'act-001',
        type: ActivityItemType.listingRemoved,
        params: const {'listingId': '4321', 'moderator': 'Moderator A'},
        timestamp: now.subtract(const Duration(minutes: 2)),
      ),
      ActivityItemEntity(
        id: 'act-002',
        type: ActivityItemType.userVerified,
        params: const {'userId': 'jansen_m', 'method': 'iDIN'},
        timestamp: now.subtract(const Duration(minutes: 15)),
      ),
      ActivityItemEntity(
        id: 'act-003',
        type: ActivityItemType.disputeEscalated,
        params: const {'disputeId': '982', 'escalatedTo': 'Senior Admin'},
        timestamp: now.subtract(const Duration(minutes: 45)),
      ),
      ActivityItemEntity(
        id: 'act-004',
        type: ActivityItemType.systemUpdate,
        params: const {'version': 'v2.4.1'},
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
    ].take(limit).toList();
  }

  Future<void> _simulateDelay() =>
      Future<void>.delayed(const Duration(milliseconds: 300));
}
