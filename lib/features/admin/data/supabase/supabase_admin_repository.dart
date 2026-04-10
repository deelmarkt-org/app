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
/// Reference: docs/screens/08-admin/01-admin-panel.md
class SupabaseAdminRepository implements AdminRepository {
  const SupabaseAdminRepository(this._client);

  // ignore: unused_field
  final SupabaseClient _client;

  @override
  Future<AdminStatsEntity> getStats() {
    // TODO: Call `get_admin_stats` RPC when migration is ready.
    throw UnimplementedError(
      'SupabaseAdminRepository.getStats() not yet implemented — '
      'awaiting admin RPC migration (P-40 Phase B)',
    );
  }

  @override
  Future<List<ActivityItemEntity>> getRecentActivity({int limit = 10}) {
    // TODO: Call `get_admin_activity` RPC when migration is ready.
    throw UnimplementedError(
      'SupabaseAdminRepository.getRecentActivity() not yet implemented — '
      'awaiting admin RPC migration (P-40 Phase B)',
    );
  }
}
