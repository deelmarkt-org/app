import 'package:equatable/equatable.dart';

import 'package:deelmarkt/core/domain/entities/scam_reason.dart';

/// DSA Art. 17 / EU AI Act statement-of-reasons payload for an
/// automated content-moderation decision.
///
/// Pure domain entity — no Flutter or Supabase imports. The `scam_flags`
/// table + Edge Function (R-44 backend portion, owned by reso) populates
/// these fields per flagged content.
///
/// Required transparency fields per DSA Art. 17(3):
///   * `ruleId`        — classifier rule identifier (machine-readable)
///   * `reasons`       — closed enum reasons (human-readable copy keys)
///   * `score`         — classifier confidence ∈ [0.0, 1.0]
///   * `modelVersion`  — semver-shaped string so users can reference it
///                       in their appeal
///   * `policyVersion` — content-policy revision the rule applied
///   * `flaggedAt`     — when the automated decision was issued
///   * `contentRef`    — opaque server reference (e.g. "listing/abc-123")
///                       so appeal moderators can pull the original
///                       content; never the raw content itself
///
/// Reference:
/// - docs/audits/2026-04-25-tier1-retrospective.md §R-44
/// - docs/epics/E06-trust-moderation.md §Scam Detection
/// - DSA Art. 17 Statement of Reasons + AI Act Art. 13 transparency
class ScamFlagStatement extends Equatable {
  const ScamFlagStatement({
    required this.ruleId,
    required this.reasons,
    required this.score,
    required this.modelVersion,
    required this.policyVersion,
    required this.flaggedAt,
    required this.contentRef,
  }) : assert(score >= 0.0 && score <= 1.0, 'score must be in [0.0, 1.0]'),
       assert(
         reasons.length != 0,
         'reasons must not be empty — use [ScamReason.other] when '
         'the classifier is opaque',
       );

  /// Machine-readable rule id, e.g. `link_pattern_v3` or `phone_regex_nl`.
  /// Stable across model versions so appeal cases can be aggregated.
  final String ruleId;

  /// Closed-enum reasons backing the localised "why was this flagged?"
  /// list. Reuses [ScamReason] (the source of truth shared with the
  /// chat scam-alert widget) so a new reason added on the backend
  /// surfaces in BOTH this widget and the chat banner without drift.
  final List<ScamReason> reasons;

  /// Classifier confidence, ∈ [0.0, 1.0]. Surfaced as a percentage in
  /// the UI for transparency, not as a binary high/low like the chat
  /// alert (which is a recipient-facing signal, not a reasons report).
  final double score;

  /// Semver-shaped string identifying the model build that issued the
  /// flag, e.g. `scam-classifier-v1.4.0`. Required by DSA Art. 17(3)(b)
  /// and the EU AI Act so appellants can cite the exact decision-maker.
  final String modelVersion;

  /// Content-policy revision applied at flagging time, e.g.
  /// `policy-2026-04`. Decouples policy updates from model updates so
  /// appeals can be classified by the rules that actually applied.
  final String policyVersion;

  final DateTime flaggedAt;

  /// Opaque server reference (e.g. `listing/abc-123`, `message/xyz`).
  /// NEVER the raw flagged content — that belongs in the moderation
  /// queue, not in user-facing transparency copy.
  final String contentRef;

  /// Confidence as a 0–100 integer percentage, suitable for surface
  /// copy. Always rounds down so a score of 0.499 reports `49%`.
  int get confidencePercent => (score * 100).floor().clamp(0, 100);

  @override
  List<Object?> get props => [
    ruleId,
    reasons,
    score,
    modelVersion,
    policyVersion,
    flaggedAt,
    contentRef,
  ];
}
