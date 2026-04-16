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

  /// Server-side verification that the current user holds the admin role.
  ///
  /// **Implementation requirement (reso):** calls the Supabase SQL function
  /// `public.is_admin()` (SECURITY DEFINER) to verify role on the server —
  /// NOT `user.appMetadata` which is writable client-side.
  ///
  /// See docs/security/threat-model-auth.md (E1, S1) and
  /// docs/adr/ADR-001-reactive-auth-guard.md for the threat context.
  ///
  /// Coordinate with reso to deploy `supabase/migrations/*_is_admin_fn.sql`
  /// before enabling the [FeatureFlags.adminServerVerify] flag.
  ///
  /// The mock implementation should return the client-side
  /// `user.appMetadata['role'] == 'admin'` check as a safe default.
  Future<bool> verifyAdminRole();
}
