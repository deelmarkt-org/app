import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/data/mock/mock_dsa_report_repository.dart';
import 'package:deelmarkt/features/profile/domain/entities/dsa_report_entity.dart';

void main() {
  group('MockDsaReportRepository — default (empty)', () {
    late MockDsaReportRepository repository;

    setUp(() {
      repository = MockDsaReportRepository();
    });

    test('getMyReports returns empty list', () async {
      expect(await repository.getMyReports(), isEmpty);
    });

    test('submit returns a DsaReportEntity with correct fields', () async {
      final result = await repository.submit(
        targetType: DsaTargetType.listing,
        targetId: 'listing-001',
        category: DsaReportCategory.fraud,
        description: 'This is a suspicious listing.',
      );

      expect(result, isA<DsaReportEntity>());
      expect(result.targetType, DsaTargetType.listing);
      expect(result.targetId, 'listing-001');
      expect(result.category, DsaReportCategory.fraud);
      expect(result.status, DsaReportStatus.pending);
      expect(result.slaDeadline.isAfter(result.reportedAt), true);
    });

    test('submit adds report to getMyReports result', () async {
      await repository.submit(
        targetType: DsaTargetType.listing,
        targetId: 'listing-001',
        category: DsaReportCategory.fraud,
        description: 'Suspicious listing.',
      );

      final reports = await repository.getMyReports();
      expect(reports.length, 1);
    });
  });

  group('MockDsaReportRepository — idempotency', () {
    late MockDsaReportRepository repository;

    setUp(() {
      repository = MockDsaReportRepository();
    });

    test('second submit for same target returns existing report', () async {
      final first = await repository.submit(
        targetType: DsaTargetType.listing,
        targetId: 'listing-001',
        category: DsaReportCategory.fraud,
        description: 'Suspicious listing.',
      );
      final second = await repository.submit(
        targetType: DsaTargetType.listing,
        targetId: 'listing-001',
        category: DsaReportCategory.counterfeit,
        description: 'Same listing, different reason.',
      );

      expect(first.id, second.id);
      expect(await repository.getMyReports(), hasLength(1));
    });

    test('different target_id creates a new report', () async {
      await repository.submit(
        targetType: DsaTargetType.listing,
        targetId: 'listing-001',
        category: DsaReportCategory.fraud,
        description: 'First report.',
      );
      await repository.submit(
        targetType: DsaTargetType.listing,
        targetId: 'listing-002',
        category: DsaReportCategory.counterfeit,
        description: 'Second report.',
      );

      expect(await repository.getMyReports(), hasLength(2));
    });
  });

  group('MockDsaReportRepository — preloaded', () {
    test('getMyReports returns preloaded reports', () async {
      final now = DateTime.now();
      final preloaded = [
        DsaReportEntity(
          id: 'pre-1',
          targetType: DsaTargetType.profile,
          targetId: 'user-001',
          category: DsaReportCategory.other,
          description: 'Fake profile.',
          reportedAt: now,
          slaDeadline: now.add(const Duration(hours: 24)),
          status: DsaReportStatus.underReview,
        ),
      ];
      final repository = MockDsaReportRepository(preloadedReports: preloaded);

      final reports = await repository.getMyReports();
      expect(reports.length, 1);
      expect(reports.first.id, 'pre-1');
    });
  });
}
