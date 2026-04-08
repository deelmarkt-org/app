import 'package:deelmarkt/core/constants.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/entities/quality_score_result.dart';
import 'package:deelmarkt/features/sell/domain/usecases/quality_score_helpers.dart';

/// Calculates a quality score (0–100) for a listing in progress.
///
/// Pure synchronous use case — no dependencies, no side effects.
/// The score determines whether the user can publish (threshold:
/// [ListingQualityThresholds.publishThreshold]).
class CalculateQualityScoreUseCase {
  const CalculateQualityScoreUseCase();

  /// Evaluates [state] against six quality criteria and returns
  /// a [QualityScoreResult] with the total score and per-field breakdown.
  QualityScoreResult call(ListingCreationState state) {
    final wordCount = qualityWordCount(state.description);

    final fields = [
      qualityField(
        'sell.photos',
        state.imageFiles.length >= ListingQualityThresholds.minPhotos,
        25,
        'sell.tipMorePhotos',
      ),
      qualityField(
        'sell.title',
        state.title.length >= ListingQualityThresholds.minTitleLength &&
            state.title.length <= ListingQualityThresholds.maxTitleLength,
        15,
        'sell.titleTip',
      ),
      qualityField(
        'sell.description',
        wordCount >= ListingQualityThresholds.minDescriptionWords,
        20,
        'sell.descriptionTip',
      ),
      qualityField('sell.price', state.priceInCents > 0, 15, 'sell.priceTip'),
      qualityField(
        'sell.category',
        state.categoryL2Id != null,
        15,
        'sell.categoryTip',
      ),
      qualityField(
        'sell.condition',
        state.condition != null,
        10,
        'sell.conditionTip',
      ),
    ];

    final totalScore = fields.fold<int>(0, (sum, f) => sum + f.points);
    return QualityScoreResult(score: totalScore, breakdown: fields);
  }
}
