/// Response DTO for the `listing-quality-score` Edge Function (R-26).
///
/// Mirrors the `ScoreResult` TypeScript interface in
/// `supabase/functions/listing-quality-score/scoring_engine.ts`.
///
/// Defensive parsing: any malformed payload throws [FormatException] with
/// a descriptive message instead of a TypeError.
library;

/// Authoritative server-side quality score result.
///
/// Returned by the Edge Function and consumed by
/// `ListingQualityScoreService`. Caller must honour [canPublish] at
/// publish time — the client-side `CalculateQualityScoreUseCase`
/// score is for real-time UI feedback only and is not authoritative.
class QualityScoreResponse {
  const QualityScoreResponse({
    required this.score,
    required this.canPublish,
    required this.breakdown,
  });

  /// Total score (0–100).
  final int score;

  /// Whether the score meets the publish threshold (40).
  final bool canPublish;

  /// Per-field contribution in canonical order — matches the Dart
  /// `CalculateQualityScoreUseCase` breakdown order so callers can
  /// diff client score vs. server score field-by-field.
  final List<QualityScoreFieldResponse> breakdown;

  /// Parses the JSON payload returned by `functions.invoke`.
  ///
  /// Throws [FormatException] on missing or wrong-typed fields —
  /// the service catches this and maps it to a ValidationException
  /// with a stable l10n key.
  factory QualityScoreResponse.fromJson(Map<String, dynamic> json) {
    final score = json['score'];
    final canPublish = json['can_publish'];
    final breakdown = json['breakdown'];
    if (score is! int || canPublish is! bool || breakdown is! List) {
      throw const FormatException(
        'QualityScoreResponse: missing or wrong-typed required fields',
      );
    }
    return QualityScoreResponse(
      score: score,
      canPublish: canPublish,
      breakdown:
          breakdown
              .whereType<Map<String, dynamic>>()
              .map(QualityScoreFieldResponse.fromJson)
              .toList(),
    );
  }
}

/// Single field contribution inside a [QualityScoreResponse.breakdown].
class QualityScoreFieldResponse {
  const QualityScoreFieldResponse({
    required this.name,
    required this.points,
    required this.maxPoints,
    required this.passed,
    required this.tipKey,
  });

  /// L10n key prefix (e.g. `sell.photos`) — matches the Dart
  /// `QualityScoreField.name`.
  final String name;

  /// Points earned (0 or maxPoints — fields are pass/fail).
  final int points;

  /// Maximum points this field can earn.
  final int maxPoints;

  /// Whether this field met its quality threshold.
  final bool passed;

  /// L10n key for the improvement tip when [passed] is false, null
  /// when the field passed.
  final String? tipKey;

  factory QualityScoreFieldResponse.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final points = json['points'];
    final maxPoints = json['max_points'];
    final passed = json['passed'];
    if (name is! String ||
        points is! int ||
        maxPoints is! int ||
        passed is! bool) {
      throw const FormatException(
        'QualityScoreFieldResponse: missing or wrong-typed required fields',
      );
    }
    final tipKeyRaw = json['tip_key'];
    return QualityScoreFieldResponse(
      name: name,
      points: points,
      maxPoints: maxPoints,
      passed: passed,
      tipKey: tipKeyRaw is String ? tipKeyRaw : null,
    );
  }
}
