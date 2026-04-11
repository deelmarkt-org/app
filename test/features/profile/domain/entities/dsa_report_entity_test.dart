import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/domain/entities/dsa_report_entity.dart';

DsaReportEntity _make({
  String id = 'r1',
  DsaTargetType targetType = DsaTargetType.listing,
  String targetId = 'listing-001',
  DsaReportCategory category = DsaReportCategory.fraud,
  String description = 'Scam listing',
  DateTime? reportedAt,
  DateTime? slaDeadline,
  DsaReportStatus status = DsaReportStatus.pending,
  DateTime? reviewedAt,
  String? resolutionNotes,
}) {
  final now = reportedAt ?? DateTime.now().subtract(const Duration(hours: 1));
  return DsaReportEntity(
    id: id,
    targetType: targetType,
    targetId: targetId,
    category: category,
    description: description,
    reportedAt: now,
    slaDeadline: slaDeadline ?? now.add(const Duration(hours: 24)),
    status: status,
    reviewedAt: reviewedAt,
    resolutionNotes: resolutionNotes,
  );
}

void main() {
  group('DsaReportEntity.isSlaBreached', () {
    test('false when sla_deadline is in the future', () {
      final report = _make(
        slaDeadline: DateTime.now().add(const Duration(hours: 20)),
      );
      expect(report.isSlaBreached, false);
    });

    test('true when sla_deadline passed and status is pending', () {
      final report = _make(
        reportedAt: DateTime.now().subtract(const Duration(hours: 26)),
        slaDeadline: DateTime.now().subtract(const Duration(hours: 2)),
        // status defaults to pending
      );
      expect(report.isSlaBreached, true);
    });

    test('true when sla_deadline passed and status is under_review', () {
      final report = _make(
        slaDeadline: DateTime.now().subtract(const Duration(hours: 1)),
        status: DsaReportStatus.underReview,
      );
      expect(report.isSlaBreached, true);
    });

    test('false when sla_deadline passed but report is actioned', () {
      final report = _make(
        slaDeadline: DateTime.now().subtract(const Duration(hours: 1)),
        status: DsaReportStatus.actioned,
      );
      expect(report.isSlaBreached, false);
    });

    test('false when sla_deadline passed but report is rejected', () {
      final report = _make(
        slaDeadline: DateTime.now().subtract(const Duration(hours: 1)),
        status: DsaReportStatus.rejected,
      );
      expect(report.isSlaBreached, false);
    });
  });

  group('DsaReportEntity.isOpen / isClosed', () {
    test('pending is open', () {
      // status defaults to pending in _make
      expect(_make().isOpen, true);
      expect(_make().isClosed, false);
    });

    test('under_review is open', () {
      expect(_make(status: DsaReportStatus.underReview).isOpen, true);
      expect(_make(status: DsaReportStatus.underReview).isClosed, false);
    });

    test('actioned is closed', () {
      expect(_make(status: DsaReportStatus.actioned).isOpen, false);
      expect(_make(status: DsaReportStatus.actioned).isClosed, true);
    });

    test('rejected is closed', () {
      expect(_make(status: DsaReportStatus.rejected).isOpen, false);
      expect(_make(status: DsaReportStatus.rejected).isClosed, true);
    });
  });

  group('DsaReportEntity equality', () {
    test('same id → equal', () {
      final a = _make(id: 'x');
      final b = _make(id: 'x', status: DsaReportStatus.actioned);
      expect(a, equals(b));
    });

    test('different id → not equal', () {
      expect(_make(id: 'a'), isNot(equals(_make(id: 'b'))));
    });

    test('hashCode consistent with equality', () {
      final a = _make(id: 'z');
      final b = _make(id: 'z');
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('DsaTargetType enum values', () {
    test('all four values exist', () {
      expect(DsaTargetType.values.length, 4);
      expect(
        DsaTargetType.values,
        containsAll([
          DsaTargetType.listing,
          DsaTargetType.message,
          DsaTargetType.profile,
          DsaTargetType.review,
        ]),
      );
    });
  });

  group('DsaReportCategory enum values', () {
    test('all six values exist', () {
      expect(DsaReportCategory.values.length, 6);
    });
  });

  group('DsaReportStatus enum values', () {
    test('all four values exist', () {
      expect(DsaReportStatus.values.length, 4);
    });
  });
}
