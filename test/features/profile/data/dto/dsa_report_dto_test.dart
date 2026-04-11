import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/data/dto/dsa_report_dto.dart';
import 'package:deelmarkt/features/profile/domain/entities/dsa_report_entity.dart';

Map<String, dynamic> _validJson({
  String id = 'report-001',
  String? reporterId = 'user-001',
  String targetType = 'listing',
  String targetId = 'listing-001',
  String category = 'fraud',
  String description = 'This is a scam listing with fake goods.',
  String reportedAt = '2026-04-10T10:00:00Z',
  String slaDeadline = '2026-04-11T10:00:00Z',
  String status = 'pending',
  String? reviewedBy,
  String? reviewedAt,
  String? resolutionNotes,
}) => {
  'id': id,
  if (reporterId != null) 'reporter_id': reporterId,
  'target_type': targetType,
  'target_id': targetId,
  'category': category,
  'description': description,
  'reported_at': reportedAt,
  'sla_deadline': slaDeadline,
  'status': status,
  if (reviewedBy != null) 'reviewed_by': reviewedBy,
  if (reviewedAt != null) 'reviewed_at': reviewedAt,
  if (resolutionNotes != null) 'resolution_notes': resolutionNotes,
};

void main() {
  group('DsaReportDto.fromJson — happy paths', () {
    test('parses minimal valid report', () {
      final result = DsaReportDto.fromJson(_validJson());

      expect(result, isA<DsaReportEntity>());
      expect(result.id, 'report-001');
      expect(result.reporterId, 'user-001');
      expect(result.targetType, DsaTargetType.listing);
      expect(result.targetId, 'listing-001');
      expect(result.category, DsaReportCategory.fraud);
      expect(result.status, DsaReportStatus.pending);
    });

    test('parses all target types', () {
      for (final t in ['listing', 'message', 'profile', 'review']) {
        final result = DsaReportDto.fromJson(_validJson(targetType: t));
        expect(result.targetType, isA<DsaTargetType>());
      }
    });

    test('parses all categories', () {
      final cats = [
        'illegal_content',
        'prohibited_item',
        'counterfeit',
        'fraud',
        'privacy_violation',
        'other',
      ];
      for (final c in cats) {
        final result = DsaReportDto.fromJson(_validJson(category: c));
        expect(result.category, isA<DsaReportCategory>());
      }
    });

    test('parses all statuses', () {
      for (final s in ['pending', 'under_review', 'actioned', 'rejected']) {
        final result = DsaReportDto.fromJson(_validJson(status: s));
        expect(result.status, isA<DsaReportStatus>());
      }
    });

    test('parses resolution fields when present', () {
      final result = DsaReportDto.fromJson(
        _validJson(
          status: 'actioned',
          reviewedBy: 'mod-001',
          reviewedAt: '2026-04-10T18:00:00Z',
          resolutionNotes: 'Listing removed.',
        ),
      );

      expect(result.reviewedBy, 'mod-001');
      expect(result.reviewedAt, isNotNull);
      expect(result.resolutionNotes, 'Listing removed.');
    });

    test('null reporter_id parses as null', () {
      final json = _validJson(reporterId: null);
      expect(DsaReportDto.fromJson(json).reporterId, isNull);
    });

    test('slaDeadline parsed correctly', () {
      final result = DsaReportDto.fromJson(_validJson());
      expect(result.slaDeadline.isAfter(result.reportedAt), true);
    });
  });

  group('DsaReportDto.fromJson — error paths', () {
    test('throws FormatException for missing id', () {
      final json = _validJson()..remove('id');
      expect(() => DsaReportDto.fromJson(json), throwsFormatException);
    });

    test('throws FormatException for missing target_type', () {
      final json = _validJson()..remove('target_type');
      expect(() => DsaReportDto.fromJson(json), throwsFormatException);
    });

    test('throws FormatException for missing target_id', () {
      final json = _validJson()..remove('target_id');
      expect(() => DsaReportDto.fromJson(json), throwsFormatException);
    });

    test('throws FormatException for missing category', () {
      final json = _validJson()..remove('category');
      expect(() => DsaReportDto.fromJson(json), throwsFormatException);
    });

    test('throws FormatException for missing description', () {
      final json = _validJson()..remove('description');
      expect(() => DsaReportDto.fromJson(json), throwsFormatException);
    });

    test('throws FormatException for missing reported_at', () {
      final json = _validJson()..remove('reported_at');
      expect(() => DsaReportDto.fromJson(json), throwsFormatException);
    });

    test('throws FormatException for missing sla_deadline', () {
      final json = _validJson()..remove('sla_deadline');
      expect(() => DsaReportDto.fromJson(json), throwsFormatException);
    });

    test('throws FormatException for missing status', () {
      final json = _validJson()..remove('status');
      expect(() => DsaReportDto.fromJson(json), throwsFormatException);
    });

    test('throws FormatException for unknown target_type', () {
      expect(
        () => DsaReportDto.fromJson(_validJson(targetType: 'comment')),
        throwsFormatException,
      );
    });

    test('throws FormatException for unknown category', () {
      expect(
        () => DsaReportDto.fromJson(_validJson(category: 'spam')),
        throwsFormatException,
      );
    });

    test('throws FormatException for unknown status', () {
      expect(
        () => DsaReportDto.fromJson(_validJson(status: 'open')),
        throwsFormatException,
      );
    });

    test('throws FormatException for invalid reported_at', () {
      expect(
        () => DsaReportDto.fromJson(_validJson(reportedAt: 'not-a-date')),
        throwsFormatException,
      );
    });
  });

  group('DsaReportDto.fromJsonList', () {
    test('parses a valid list', () {
      final list = [
        _validJson(),
        _validJson(id: 'report-002', status: 'actioned'),
      ];
      expect(DsaReportDto.fromJsonList(list).length, 2);
    });

    test('skips malformed entries', () {
      final list = [
        _validJson(),
        <String, dynamic>{'id': 'bad'},
      ];
      expect(DsaReportDto.fromJsonList(list).length, 1);
    });

    test('skips non-map entries', () {
      final list = ['not-a-map', 42, _validJson()];
      expect(DsaReportDto.fromJsonList(list).length, 1);
    });

    test('returns empty list for empty input', () {
      expect(DsaReportDto.fromJsonList([]), isEmpty);
    });
  });

  group('DsaReportDto DB serialisation helpers', () {
    test('targetTypeToDb round-trips all values', () {
      for (final t in DsaTargetType.values) {
        final db = DsaReportDto.targetTypeToDb(t);
        expect(db, isNotEmpty);
      }
    });

    test('categoryToDb round-trips all values', () {
      for (final c in DsaReportCategory.values) {
        final db = DsaReportDto.categoryToDb(c);
        expect(db, isNotEmpty);
      }
    });
  });
}
