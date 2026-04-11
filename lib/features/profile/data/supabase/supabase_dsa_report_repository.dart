import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/profile/data/dto/dsa_report_dto.dart';
import 'package:deelmarkt/features/profile/domain/entities/dsa_report_entity.dart';
import 'package:deelmarkt/features/profile/domain/repositories/dsa_report_repository.dart';

/// Supabase implementation of [DsaReportRepository].
///
/// [submit] calls the server-side `submit_dsa_report()` RPC (SECURITY INVOKER)
/// which sets [slaDeadline] = now() + 24h and enforces one-report-per-target.
/// [getMyReports] reads directly from [dsa_reports] — RLS limits rows to the
/// authenticated user's own reports.
///
/// Reference: docs/epics/E06-trust-moderation.md §DSA Transparency Module
/// Reference: docs/SPRINT-PLAN.md R-38
class SupabaseDsaReportRepository implements DsaReportRepository {
  const SupabaseDsaReportRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'dsa_reports';

  @override
  Future<DsaReportEntity> submit({
    required DsaTargetType targetType,
    required String targetId,
    required DsaReportCategory category,
    required String description,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User must be authenticated to submit a DSA report');
    }

    try {
      final response = await _client.rpc(
        'submit_dsa_report',
        params: {
          'p_target_type': DsaReportDto.targetTypeToDb(targetType),
          'p_target_id': targetId,
          'p_category': DsaReportDto.categoryToDb(category),
          'p_description': description,
        },
      );

      final rows = response as List<dynamic>;
      if (rows.isEmpty) {
        throw Exception('submit_dsa_report returned no rows');
      }
      return DsaReportDto.fromJson(rows.first as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to submit DSA report: ${e.message}');
    }
  }

  @override
  Future<List<DsaReportEntity>> getMyReports() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User must be authenticated to fetch DSA reports');
    }

    try {
      final response = await _client
          .from(_table)
          .select()
          .order('reported_at', ascending: false);

      return DsaReportDto.fromJsonList(response as List<dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch DSA reports: ${e.message}');
    }
  }
}
