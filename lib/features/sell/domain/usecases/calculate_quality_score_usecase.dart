import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/entities/quality_score_result.dart';
import 'package:deelmarkt/features/sell/domain/quality_score_helpers.dart';

/// Calculates a quality score (0–100) for a listing in progress.
///
/// Pure synchronous use case — no dependencies, no side effects.
/// The score determines whether the user can publish (threshold:
/// [ListingQualityThresholds.publishThreshold]).
///
/// The per-field evaluation and weights live in
/// [buildQualityBreakdown] (in `quality_score_helpers.dart`) so the same
/// data can be shared with the authoritative server-side R-26 Edge
/// Function without duplicating the scoring logic.
class CalculateQualityScoreUseCase {
  const CalculateQualityScoreUseCase();

  /// Evaluates [state] and returns a [QualityScoreResult] with the
  /// total score and per-field breakdown.
  QualityScoreResult call(ListingCreationState state) {
    final breakdown = buildQualityBreakdown(state);
    final total = breakdown.fold<int>(0, (sum, f) => sum + f.points);
    return QualityScoreResult(score: total, breakdown: breakdown);
  }
}
