import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/profile/data/supabase/supabase_dsa_report_repository.dart';
import 'package:deelmarkt/features/profile/domain/entities/dsa_report_entity.dart';

/// Minimal unauthenticated Supabase client for auth-guard tests.
/// All RPC/table calls will throw — we only verify the auth check fires.
SupabaseClient _unauthClient() =>
    SupabaseClient('https://test.supabase.co', 'test-anon-key');

void main() {
  late SupabaseDsaReportRepository repository;

  setUp(() {
    repository = SupabaseDsaReportRepository(_unauthClient());
  });

  group('submit — auth guard', () {
    test('throws when user is not authenticated', () async {
      await expectLater(
        () => repository.submit(
          targetType: DsaTargetType.listing,
          targetId: 'listing-001',
          category: DsaReportCategory.fraud,
          description: 'Suspicious listing',
        ),
        throwsA(anything),
      );
    });
  });

  group('getMyReports — auth guard', () {
    test('throws when user is not authenticated', () async {
      await expectLater(() => repository.getMyReports(), throwsA(anything));
    });
  });

  group('DsaReportEntity business logic (no Supabase required)', () {
    test('pending report within SLA is not breached', () {
      final now = DateTime.now();
      final report = DsaReportEntity(
        id: 'r1',
        targetType: DsaTargetType.listing,
        targetId: 'l1',
        category: DsaReportCategory.fraud,
        description: 'Test report',
        reportedAt: now,
        slaDeadline: now.add(const Duration(hours: 20)),
        status: DsaReportStatus.pending,
      );
      expect(report.isSlaBreached, false);
      expect(report.isOpen, true);
    });

    test('pending report past SLA is breached', () {
      final now = DateTime.now();
      final report = DsaReportEntity(
        id: 'r2',
        targetType: DsaTargetType.listing,
        targetId: 'l1',
        category: DsaReportCategory.fraud,
        description: 'Test report',
        reportedAt: now.subtract(const Duration(hours: 26)),
        slaDeadline: now.subtract(const Duration(hours: 2)),
        status: DsaReportStatus.pending,
      );
      expect(report.isSlaBreached, true);
    });

    test('actioned report is never SLA breached', () {
      final now = DateTime.now();
      final report = DsaReportEntity(
        id: 'r3',
        targetType: DsaTargetType.message,
        targetId: 'm1',
        category: DsaReportCategory.illegalContent,
        description: 'Illegal content in message',
        reportedAt: now.subtract(const Duration(hours: 30)),
        slaDeadline: now.subtract(const Duration(hours: 6)),
        status: DsaReportStatus.actioned,
        reviewedAt: now.subtract(const Duration(hours: 10)),
      );
      expect(report.isSlaBreached, false);
      expect(report.isClosed, true);
    });

    test('rejected report is closed', () {
      final now = DateTime.now();
      final report = DsaReportEntity(
        id: 'r4',
        targetType: DsaTargetType.review,
        targetId: 'rv1',
        category: DsaReportCategory.other,
        description: 'Report reason',
        reportedAt: now,
        slaDeadline: now.add(const Duration(hours: 24)),
        status: DsaReportStatus.rejected,
      );
      expect(report.isClosed, true);
      expect(report.isOpen, false);
    });
  });
}
