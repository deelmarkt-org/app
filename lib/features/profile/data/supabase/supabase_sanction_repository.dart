import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/profile/data/dto/sanction_dto.dart';
import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';
import 'package:deelmarkt/features/profile/domain/exceptions/sanction_exceptions.dart';
import 'package:deelmarkt/features/profile/domain/repositories/sanction_repository.dart';

/// Supabase implementation of [SanctionRepository].
///
/// All write operations (issuance, appeal decisions, reinstatement) are
/// service_role-only at the DB level — this repository only exposes the
/// read path and the [submitAppeal] RPC for the authenticated user.
///
/// Reference: docs/epics/E06-trust-moderation.md §Account Suspension & Recovery
/// Reference: docs/SPRINT-PLAN.md R-37
class SupabaseSanctionRepository implements SanctionRepository {
  const SupabaseSanctionRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'account_sanctions';

  /// Returns the current active suspension or ban via the server-side
  /// [get_active_sanction] RPC. Using an RPC avoids client-side clock
  /// manipulation (same pattern as [submit_review] in R-36).
  @override
  Future<SanctionEntity?> getActiveSanction(String userId) async {
    try {
      final response = await _client.rpc(
        'get_active_sanction',
        params: {'p_user_id': userId},
      );

      final rows = response as List<dynamic>;
      if (rows.isEmpty) return null;

      return SanctionDto.fromJson(rows.first as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      // PGRST116 = no rows — treated as "no active sanction", not an error.
      if (e.code == 'PGRST116') return null;
      throw UnknownSanctionError(
        'Failed to fetch active sanction for user $userId: ${e.message}',
      );
    }
  }

  @override
  Future<List<SanctionEntity>> getAll(String userId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return SanctionDto.fromJsonList(response as List<dynamic>);
    } on PostgrestException catch (e) {
      throw Exception(
        'Failed to fetch sanctions for user $userId: ${e.message}',
      );
    }
  }

  @override
  Future<SanctionEntity> submitAppeal(
    String sanctionId,
    String appealBody,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Cannot submit appeal: user is not authenticated');
    }

    try {
      final response = await _client.rpc(
        'submit_appeal',
        params: {'p_sanction_id': sanctionId, 'p_appeal_body': appealBody},
      );

      final rows = response as List<dynamic>;
      if (rows.isEmpty) {
        throw const UnknownSanctionError('submit_appeal RPC returned no rows');
      }
      return SanctionDto.fromJson(rows.first as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw mapSanctionError(e);
    }
  }

  /// Maps a [PostgrestException] from the sanction RPCs to the correct
  /// [SanctionException] subclass. Kept in the data layer so the domain
  /// remains pure Dart (CLAUDE.md §1.2).
  ///
  /// Exposed for testing via `@visibleForTesting`; call sites within the
  /// production code should go through [submitAppeal].
  ///
  /// Mapping rules:
  /// - Message contains "14 days" / "14-day" → [AppealWindowExpired]
  /// - Message contains "final decision" / "counter-appeal" → [AppealAlreadyResolved]
  /// - [PostgrestException.code] is "PGRST116" (no rows) → [SanctionNotFound]
  /// - HTTP status 429 or message contains "rate" → [AppealRateLimited]
  /// - Everything else → [UnknownSanctionError]
  @visibleForTesting
  static SanctionException mapSanctionError(PostgrestException e) {
    final msg = e.message.toLowerCase();

    if (msg.contains('14 day') || msg.contains('14-day')) {
      return const AppealWindowExpired();
    }
    if (msg.contains('final decision') || msg.contains('counter-appeal')) {
      return const AppealAlreadyResolved();
    }
    if (e.code == 'PGRST116') {
      return const SanctionNotFound();
    }
    if ((e.details?.toString().contains('429') ?? false) ||
        msg.contains('rate')) {
      return const AppealRateLimited();
    }
    return UnknownSanctionError(e.message);
  }
}
