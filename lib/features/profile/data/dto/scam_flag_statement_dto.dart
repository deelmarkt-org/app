import 'package:flutter/foundation.dart';

import 'package:deelmarkt/core/domain/entities/scam_flag_statement.dart';
import 'package:deelmarkt/core/domain/entities/scam_reason.dart';

/// Maps a `get_active_scam_flag(uuid)` JSON row to [ScamFlagStatement].
///
/// The RPC returns either `null` (no active flag — UI conditionally hides
/// the DSA panel) or a JSON object with the 8 DSA Art. 17 fields. Field
/// names are snake_case server-side and map to camelCase on the entity.
///
/// Reference: `supabase/migrations/20260503161500_r44_scam_flags.sql`
/// Reference: docs/audits/2026-04-25-tier1-retrospective.md §R-44
class ScamFlagStatementDto {
  ScamFlagStatementDto._();

  /// Parses a single JSON row. Throws [FormatException] on malformed input
  /// so the provider can surface an [AsyncError] rather than silently
  /// hide the DSA panel for a real flagged user.
  static ScamFlagStatement fromJson(Map<String, dynamic> json) {
    final ruleId = json['rule_id'] as String?;
    final reasonsRaw = json['reasons'] as List<dynamic>?;
    final score = (json['score'] as num?)?.toDouble();
    final modelVersion = json['model_version'] as String?;
    final policyVersion = json['policy_version'] as String?;
    final flaggedAtRaw = json['flagged_at'] as String?;
    final contentRef = json['content_ref'] as String?;

    if (ruleId == null ||
        ruleId.isEmpty ||
        reasonsRaw == null ||
        reasonsRaw.isEmpty ||
        score == null ||
        modelVersion == null ||
        modelVersion.isEmpty ||
        policyVersion == null ||
        policyVersion.isEmpty ||
        flaggedAtRaw == null ||
        contentRef == null ||
        contentRef.isEmpty) {
      throw const FormatException(
        'ScamFlagStatementDto.fromJson: missing required field(s)',
      );
    }

    final reasons = reasonsRaw
        .whereType<String>()
        .map(ScamReason.fromDb) // unknown values fall back to `other`
        .toList(growable: false);
    if (reasons.isEmpty) {
      throw const FormatException(
        'ScamFlagStatementDto.fromJson: reasons array contained no usable strings',
      );
    }

    final flaggedAt = DateTime.tryParse(flaggedAtRaw);
    if (flaggedAt == null) {
      throw FormatException(
        'ScamFlagStatementDto.fromJson: unparseable flagged_at: $flaggedAtRaw',
      );
    }

    return ScamFlagStatement(
      ruleId: ruleId,
      reasons: reasons,
      score: score,
      modelVersion: modelVersion,
      policyVersion: policyVersion,
      flaggedAt: flaggedAt,
      contentRef: contentRef,
      contentDisplayLabel: json['content_display_label'] as String?,
    );
  }

  /// Convenience for the RPC's `null` → "no active flag" semantic.
  static ScamFlagStatement? fromJsonOrNull(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map<String, dynamic>) {
      debugPrint(
        'ScamFlagStatementDto.fromJsonOrNull: unexpected RPC shape — $raw',
      );
      return null;
    }
    return fromJson(raw);
  }
}
