import 'package:flutter/foundation.dart';

import 'package:deelmarkt/features/profile/domain/entities/dsa_report_entity.dart';

/// Maps raw Supabase JSON rows from [dsa_reports] to [DsaReportEntity].
///
/// Reference: docs/SPRINT-PLAN.md R-38
class DsaReportDto {
  DsaReportDto._();

  static DsaReportEntity fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final targetTypeRaw = json['target_type'] as String?;
    final targetId = json['target_id'] as String?;
    final categoryRaw = json['category'] as String?;
    final description = json['description'] as String?;
    final reportedAtRaw = json['reported_at'] as String?;
    final slaDeadlineRaw = json['sla_deadline'] as String?;
    final statusRaw = json['status'] as String?;

    if (id == null ||
        id.isEmpty ||
        targetTypeRaw == null ||
        targetId == null ||
        targetId.isEmpty ||
        categoryRaw == null ||
        description == null ||
        description.isEmpty ||
        reportedAtRaw == null ||
        slaDeadlineRaw == null ||
        statusRaw == null) {
      throw const FormatException(
        'DsaReportDto.fromJson: missing required fields',
      );
    }

    final targetType = _parseTargetType(targetTypeRaw);
    final category = _parseCategory(categoryRaw);
    final status = _parseStatus(statusRaw);

    return DsaReportEntity(
      id: id,
      reporterId: json['reporter_id'] as String?,
      targetType: targetType,
      targetId: targetId,
      category: category,
      description: description,
      reportedAt: DateTime.parse(reportedAtRaw),
      slaDeadline: DateTime.parse(slaDeadlineRaw),
      status: status,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: _parseDate(json['reviewed_at']),
      resolutionNotes: json['resolution_notes'] as String?,
    );
  }

  static DsaTargetType _parseTargetType(String raw) {
    return switch (raw) {
      'listing' => DsaTargetType.listing,
      'message' => DsaTargetType.message,
      'profile' => DsaTargetType.profile,
      'review' => DsaTargetType.review,
      _ => throw FormatException('DsaReportDto: unknown target_type: $raw'),
    };
  }

  static DsaReportCategory _parseCategory(String raw) {
    return switch (raw) {
      'illegal_content' => DsaReportCategory.illegalContent,
      'prohibited_item' => DsaReportCategory.prohibitedItem,
      'counterfeit' => DsaReportCategory.counterfeit,
      'fraud' => DsaReportCategory.fraud,
      'privacy_violation' => DsaReportCategory.privacyViolation,
      'other' => DsaReportCategory.other,
      _ => throw FormatException('DsaReportDto: unknown category: $raw'),
    };
  }

  static DsaReportStatus _parseStatus(String raw) {
    return switch (raw) {
      'pending' => DsaReportStatus.pending,
      'under_review' => DsaReportStatus.underReview,
      'actioned' => DsaReportStatus.actioned,
      'rejected' => DsaReportStatus.rejected,
      _ => throw FormatException('DsaReportDto: unknown status: $raw'),
    };
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw is! String) return null;
    return DateTime.tryParse(raw);
  }

  /// Parses a list, silently skipping malformed entries.
  static List<DsaReportEntity> fromJsonList(List<dynamic> list) {
    final result = <DsaReportEntity>[];
    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      try {
        result.add(fromJson(item));
      } on FormatException catch (e) {
        debugPrint('DsaReportDto.fromJsonList: skipping malformed row — $e');
        continue;
      }
    }
    return result;
  }

  static String targetTypeToDb(DsaTargetType type) {
    return switch (type) {
      DsaTargetType.listing => 'listing',
      DsaTargetType.message => 'message',
      DsaTargetType.profile => 'profile',
      DsaTargetType.review => 'review',
    };
  }

  static String categoryToDb(DsaReportCategory category) {
    return switch (category) {
      DsaReportCategory.illegalContent => 'illegal_content',
      DsaReportCategory.prohibitedItem => 'prohibited_item',
      DsaReportCategory.counterfeit => 'counterfeit',
      DsaReportCategory.fraud => 'fraud',
      DsaReportCategory.privacyViolation => 'privacy_violation',
      DsaReportCategory.other => 'other',
    };
  }
}
