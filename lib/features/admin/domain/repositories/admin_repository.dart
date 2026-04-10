import 'package:deelmarkt/features/admin/domain/entities/activity_item_entity.dart';
import 'package:deelmarkt/features/admin/domain/entities/admin_stats_entity.dart';

/// Admin repository interface — domain layer.
///
/// Implementations: MockAdminRepository (dev), SupabaseAdminRepository (prod).
/// Swapped via Riverpod provider overrides — no conditional logic (ADR-MOCK-SWAP).
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
abstract class AdminRepository {
  /// Get aggregated admin dashboard statistics.
  Future<AdminStatsEntity> getStats();

  /// Get recent admin activity events, ordered newest-first.
  Future<List<ActivityItemEntity>> getRecentActivity({int limit = 10});
}
