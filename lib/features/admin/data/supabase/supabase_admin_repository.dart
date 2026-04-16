import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/admin/domain/entities/activity_item_entity.dart';
import 'package:deelmarkt/features/admin/domain/entities/admin_stats_entity.dart';
import 'package:deelmarkt/features/admin/domain/repositories/admin_repository.dart';

/// Supabase implementation of [AdminRepository].
///
/// TODO: Implement when admin RPCs are ready (P-40 Phase B).
/// The RPCs will be service_role-gated at the DB level — this repository
/// only exposes the read path for authenticated admin users.
///
/// SECURITY-TODO (P-40 Phase B):
///   • All RPC calls must use the service_role key — never the anon key.
///   • Verify admin role claim from JWT before executing any RPC.
///   • Row-level security on admin_audit_log must prevent non-admins from
///     reading other users' data even if the RPC is called directly.
///   • Rate-limit admin endpoints at the Edge Function / API gateway level.
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class SupabaseAdminRepository implements AdminRepository {
  const SupabaseAdminRepository(this._client);

  // ignore: unused_field
  final SupabaseClient _client;

  @override
  Future<AdminStatsEntity> getStats() async {
    // TODO(P-40 Phase B): Replace with `get_admin_stats` RPC call when
    // migration is ready. Returns all-zero stats until then so production
    // admin builds show an empty dashboard instead of an error screen.
    return const AdminStatsEntity(
      openDisputes: 0,
      dsaNoticesWithin24h: 0,
      activeListings: 0,
      escrowAmountCents: 0,
      flaggedListings: 0,
      reportedUsers: 0,
      approvedCount: 0,
    );
  }

  @override
  Future<List<ActivityItemEntity>> getRecentActivity({int limit = 10}) async {
    // TODO(P-40 Phase B): Replace with `get_admin_activity` RPC call when
    // migration is ready. Returns empty list until then.
    return const [];
  }

  @override
  Future<bool> verifyAdminRole() async {
    // TODO(Phase 1.12 — reso): Replace with `public.is_admin()` SECURITY DEFINER
    // RPC call once the SQL function is deployed.
    //
    //   final result = await _client.rpc('is_admin');
    //   return result as bool? ?? false;
    //
    // Do NOT use `_client.auth.currentUser?.appMetadata['role']` here —
    // that is client-side and writable by an attacker (threat E1 in
    // docs/security/threat-model-auth.md).
    //
    // This method falls back to false until reso deploys the SQL function and
    // the [FeatureFlags.adminServerVerify] flag is enabled.
    return false;
  }
}
