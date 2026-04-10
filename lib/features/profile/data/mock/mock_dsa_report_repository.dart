import 'package:deelmarkt/features/profile/domain/entities/dsa_report_entity.dart';
import 'package:deelmarkt/features/profile/domain/repositories/dsa_report_repository.dart';

/// Mock implementation of [DsaReportRepository] for development + widget tests.
///
/// Default: [getMyReports] returns an empty list (clean state).
/// Provide [preloadedReports] to seed the repository with existing reports.
///
/// Reference: docs/SPRINT-PLAN.md R-38
class MockDsaReportRepository implements DsaReportRepository {
  MockDsaReportRepository({List<DsaReportEntity>? preloadedReports})
    : _reports = preloadedReports?.toList() ?? [];

  final List<DsaReportEntity> _reports;

  @override
  Future<DsaReportEntity> submit({
    required DsaTargetType targetType,
    required String targetId,
    required DsaReportCategory category,
    required String description,
  }) async {
    // Idempotent: return existing if same (target_type, target_id) exists.
    final existing = _reports.where(
      (r) => r.targetType == targetType && r.targetId == targetId,
    );
    if (existing.isNotEmpty) return existing.first;

    final now = DateTime.now();
    final report = DsaReportEntity(
      id: 'mock-dsa-${_reports.length + 1}',
      reporterId: 'mock-user-001',
      targetType: targetType,
      targetId: targetId,
      category: category,
      description: description,
      reportedAt: now,
      slaDeadline: now.add(const Duration(hours: 24)),
      status: DsaReportStatus.pending,
    );
    _reports.insert(0, report);
    return report;
  }

  @override
  Future<List<DsaReportEntity>> getMyReports() async =>
      List.unmodifiable(_reports);
}
