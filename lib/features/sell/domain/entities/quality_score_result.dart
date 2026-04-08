import 'package:equatable/equatable.dart';

import 'package:deelmarkt/core/constants.dart';

/// Result of the listing quality score calculation.
///
/// Pure domain entity — no Flutter/Supabase imports.
/// Used by [CalculateQualityScoreUseCase] to evaluate listing completeness.
class QualityScoreResult extends Equatable {
  const QualityScoreResult({required this.score, required this.breakdown});

  /// Total quality score (0–100).
  final int score;

  /// Per-field breakdown of points earned vs. maximum.
  final List<QualityScoreField> breakdown;

  /// Whether this listing meets the publish threshold.
  ///
  /// Threshold: [ListingQualityThresholds.publishThreshold].
  bool get canPublish => score >= ListingQualityThresholds.publishThreshold;

  @override
  List<Object?> get props => [score, breakdown];
}

/// Individual field contribution to the quality score.
///
/// Each field has a maximum number of points and a pass/fail status.
/// When [passed] is false, [tipKey] contains an l10n key for an
/// improvement suggestion shown to the user.
class QualityScoreField extends Equatable {
  const QualityScoreField({
    required this.name,
    required this.points,
    required this.maxPoints,
    required this.passed,
    this.tipKey,
  });

  /// L10n key prefix (e.g. 'sell.photos').
  final String name;

  /// Points earned for this field.
  final int points;

  /// Maximum possible points for this field.
  final int maxPoints;

  /// Whether the field meets the quality threshold.
  final bool passed;

  /// L10n key for improvement tip, null when [passed] is true.
  final String? tipKey;

  @override
  List<Object?> get props => [name, points, maxPoints, passed, tipKey];
}
