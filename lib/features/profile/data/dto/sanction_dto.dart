import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';

/// Maps raw Supabase JSON rows from [account_sanctions] to [SanctionEntity].
///
/// Reference: docs/SPRINT-PLAN.md R-37
class SanctionDto {
  SanctionDto._();

  static SanctionEntity fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final userId = json['user_id'] as String?;
    final typeRaw = json['type'] as String?;
    final reason = json['reason'] as String?;
    final createdAtRaw = json['created_at'] as String?;

    if (id == null ||
        id.isEmpty ||
        userId == null ||
        userId.isEmpty ||
        typeRaw == null ||
        reason == null ||
        reason.isEmpty ||
        createdAtRaw == null) {
      throw const FormatException(
        'SanctionDto.fromJson: missing required fields',
      );
    }

    final type = SanctionType.values.firstWhere(
      (e) => e.name == typeRaw,
      orElse:
          () =>
              throw FormatException(
                'SanctionDto.fromJson: unknown type: $typeRaw',
              ),
    );

    final decisionRaw = json['appeal_decision'] as String?;
    final appealDecision =
        decisionRaw == null
            ? null
            : AppealDecision.values.firstWhere(
              (e) => e.name == decisionRaw,
              orElse:
                  () =>
                      throw FormatException(
                        'SanctionDto.fromJson: unknown appeal_decision: $decisionRaw',
                      ),
            );

    return SanctionEntity(
      id: id,
      userId: userId,
      type: type,
      reason: reason,
      createdAt: DateTime.parse(createdAtRaw),
      expiresAt: _parseDate(json['expires_at']),
      appealedAt: _parseDate(json['appealed_at']),
      appealBody: json['appeal_body'] as String?,
      appealDecision: appealDecision,
      resolvedAt: _parseDate(json['resolved_at']),
    );
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw is! String) return null;
    return DateTime.tryParse(raw);
  }

  /// Parses a list, silently skipping malformed entries.
  static List<SanctionEntity> fromJsonList(List<dynamic> list) {
    final result = <SanctionEntity>[];
    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      try {
        result.add(fromJson(item));
      } on FormatException {
        continue;
      }
    }
    return result;
  }
}
