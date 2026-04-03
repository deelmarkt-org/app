import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/entities/quality_score_result.dart';

/// Calculates a quality score (0–100) for a listing in progress.
///
/// Pure synchronous use case — no dependencies, no side effects.
/// The score determines whether the user can publish (threshold: 40).
class CalculateQualityScoreUseCase {
  const CalculateQualityScoreUseCase();

  /// Evaluates [state] against six quality criteria and returns
  /// a [QualityScoreResult] with the total score and per-field breakdown.
  QualityScoreResult call(ListingCreationState state) {
    final photosOk = state.imageFiles.length >= 3;
    final titleOk = state.title.length >= 10 && state.title.length <= 60;
    final descriptionWordCount =
        state.description
            .trim()
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .length;
    final descriptionOk = descriptionWordCount >= 50;
    final priceOk = state.priceInCents > 0;
    final categoryOk = state.categoryL2Id != null;
    final conditionOk = state.condition != null;

    final fields = [
      QualityScoreField(
        name: 'sell.photos',
        points: photosOk ? 25 : 0,
        maxPoints: 25,
        passed: photosOk,
        tipKey: photosOk ? null : 'sell.tipMorePhotos',
      ),
      QualityScoreField(
        name: 'sell.title',
        points: titleOk ? 15 : 0,
        maxPoints: 15,
        passed: titleOk,
        tipKey: titleOk ? null : 'sell.titleTip',
      ),
      QualityScoreField(
        name: 'sell.description',
        points: descriptionOk ? 20 : 0,
        maxPoints: 20,
        passed: descriptionOk,
        tipKey: descriptionOk ? null : 'sell.descriptionTip',
      ),
      QualityScoreField(
        name: 'sell.price',
        points: priceOk ? 15 : 0,
        maxPoints: 15,
        passed: priceOk,
        tipKey: priceOk ? null : 'sell.priceTip',
      ),
      QualityScoreField(
        name: 'sell.category',
        points: categoryOk ? 15 : 0,
        maxPoints: 15,
        passed: categoryOk,
        tipKey: categoryOk ? null : 'sell.categoryTip',
      ),
      QualityScoreField(
        name: 'sell.condition',
        points: conditionOk ? 10 : 0,
        maxPoints: 10,
        passed: conditionOk,
        tipKey: conditionOk ? null : 'sell.conditionTip',
      ),
    ];

    final totalScore = fields.fold<int>(0, (sum, field) => sum + field.points);

    return QualityScoreResult(score: totalScore, breakdown: fields);
  }
}
