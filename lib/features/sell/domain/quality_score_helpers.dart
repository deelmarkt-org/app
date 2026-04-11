import 'package:deelmarkt/core/constants.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/entities/quality_score_result.dart';

// Local alias so the per-field list below stays readable without hiding
// that every number comes from the shared constants (Dart↔TS parity).
typedef _Q = ListingQualityThresholds;

/// Counts whitespace-separated non-empty tokens in [text].
int qualityWordCount(String text) =>
    text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

/// Builds a pass/fail [QualityScoreField] with the localisation tip key
/// attached only when the field fails.
QualityScoreField qualityField(
  String name,
  bool passed,
  int maxPoints,
  String tipKey,
) => QualityScoreField(
  name: name,
  points: passed ? maxPoints : 0,
  maxPoints: maxPoints,
  passed: passed,
  tipKey: passed ? null : tipKey,
);

/// Evaluates [state] against the six quality criteria and returns the
/// per-field breakdown in the canonical order shared with the R-26
/// Edge Function's `scoring_engine.ts`.
List<QualityScoreField> buildQualityBreakdown(ListingCreationState state) {
  final words = qualityWordCount(state.description);
  final titleLen = state.title.length;
  return [
    qualityField(
      'sell.photos',
      state.imageFiles.length >= _Q.minPhotos,
      _Q.photosWeight,
      'sell.tipMorePhotos',
    ),
    qualityField(
      'sell.title',
      titleLen >= _Q.minTitleLength && titleLen <= _Q.maxTitleLength,
      _Q.titleWeight,
      'sell.titleTip',
    ),
    qualityField(
      'sell.description',
      words >= _Q.minDescriptionWords,
      _Q.descriptionWeight,
      'sell.descriptionTip',
    ),
    qualityField(
      'sell.price',
      state.priceInCents > 0,
      _Q.priceWeight,
      'sell.priceTip',
    ),
    qualityField(
      'sell.category',
      state.categoryL2Id != null,
      _Q.categoryWeight,
      'sell.categoryTip',
    ),
    qualityField(
      'sell.condition',
      state.condition != null,
      _Q.conditionWeight,
      'sell.conditionTip',
    ),
  ];
}
