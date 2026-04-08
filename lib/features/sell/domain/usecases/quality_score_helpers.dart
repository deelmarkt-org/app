import 'package:deelmarkt/features/sell/domain/entities/quality_score_result.dart';

int qualityWordCount(String text) =>
    text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

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
