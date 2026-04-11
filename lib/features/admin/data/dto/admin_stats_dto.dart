import 'package:deelmarkt/features/admin/domain/entities/admin_stats_entity.dart';

/// DTO for converting Supabase REST JSON to [AdminStatsEntity].
///
/// Defensive parsing — validates required fields, falls back to 0 for
/// missing numeric values.
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class AdminStatsDto {
  const AdminStatsDto._();

  /// Parse a Supabase JSON row from admin stats RPC.
  static AdminStatsEntity fromJson(Map<String, dynamic> json) {
    return AdminStatsEntity(
      openDisputes: (json['open_disputes'] as num?)?.toInt() ?? 0,
      dsaNoticesWithin24h:
          (json['dsa_notices_within_24h'] as num?)?.toInt() ?? 0,
      activeListings: (json['active_listings'] as num?)?.toInt() ?? 0,
      escrowAmountCents: (json['escrow_amount_cents'] as num?)?.toInt() ?? 0,
      flaggedListings: (json['flagged_listings'] as num?)?.toInt() ?? 0,
      reportedUsers: (json['reported_users'] as num?)?.toInt() ?? 0,
      approvedCount: (json['approved_count'] as num?)?.toInt() ?? 0,
    );
  }
}
