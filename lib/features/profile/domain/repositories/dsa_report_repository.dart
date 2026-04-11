import 'package:deelmarkt/features/profile/domain/entities/dsa_report_entity.dart';

/// Repository interface for DSA notice-and-action reports.
///
/// Reference: docs/epics/E06-trust-moderation.md §DSA Transparency Module
/// Reference: docs/SPRINT-PLAN.md R-38
abstract class DsaReportRepository {
  /// Files a DSA notice-and-action report against [targetType]/[targetId].
  ///
  /// Idempotent: a second call for the same (reporter, target) pair returns the
  /// existing report without creating a duplicate.
  Future<DsaReportEntity> submit({
    required DsaTargetType targetType,
    required String targetId,
    required DsaReportCategory category,
    required String description,
  });

  /// Returns all DSA reports filed by the current authenticated user,
  /// ordered newest first.
  Future<List<DsaReportEntity>> getMyReports();
}
