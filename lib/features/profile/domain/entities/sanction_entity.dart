import 'package:deelmarkt/core/domain/entities/scam_flag_statement.dart';

/// Account sanction types. Matches the `sanction_type` DB enum (migration R-37).
///
/// Only [suspension] and [ban] block account access.
/// [warning] is informational only — the user can still transact.
enum SanctionType { warning, suspension, ban }

/// Moderator's decision on a user's appeal.
/// Matches the `appeal_decision_t` DB enum (migration R-37).
enum AppealDecision {
  /// Appeal reviewed — sanction stands.
  upheld,

  /// Appeal accepted — sanction lifted, account reinstated.
  overturned,
}

/// A platform-issued sanction against a user account.
///
/// Sanctions flow: issued (service_role) → [SanctionType.warning] stays
/// informational; [SanctionType.suspension]/[SanctionType.ban] block access
/// until [expiresAt] passes or appeal is [AppealDecision.overturned].
///
/// Reference: docs/epics/E06-trust-moderation.md §Account Suspension & Recovery
/// Reference: docs/SPRINT-PLAN.md R-37
class SanctionEntity {
  const SanctionEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.reason,
    required this.createdAt,
    this.expiresAt,
    this.appealedAt,
    this.appealBody,
    this.appealDecision,
    this.resolvedAt,
    this.scamFlagStatement,
  });

  final String id;
  final String userId;
  final SanctionType type;

  /// Plain-language reason for the sanction. Never a vague "policy violation".
  final String reason;

  final DateTime createdAt;

  /// Null for permanent bans. Set for temporary suspensions (e.g. 7/14/30 days).
  final DateTime? expiresAt;

  /// When the user submitted their appeal. Null if no appeal yet.
  final DateTime? appealedAt;

  /// The appeal text submitted by the user.
  final String? appealBody;

  /// Moderator's final decision. Null while pending or if not appealed.
  final AppealDecision? appealDecision;

  /// When the appeal was resolved by a moderator.
  final DateTime? resolvedAt;

  /// DSA Art. 17 statement of reasons for the automated decision that
  /// produced this sanction, when one applies. `null` for sanctions
  /// issued by a human moderator (no automated classifier output to
  /// disclose).
  ///
  /// Surfaced by the [ScamFlagStatementOfReasons] widget on the
  /// suspension gate so the user can see the rule, confidence, model,
  /// and policy version that drove the automated decision — and link
  /// directly into the appeal flow (R-44 wiring; backend portion owned
  /// by reso).
  final ScamFlagStatement? scamFlagStatement;

  /// Whether this sanction currently blocks account access.
  ///
  /// [SanctionType.warning] never blocks. A sanction stops being active if
  /// it was overturned on appeal or has naturally expired.
  bool get isActive {
    if (type == SanctionType.warning) return false;
    if (appealDecision == AppealDecision.overturned) return false;
    if (expiresAt != null && expiresAt!.isBefore(DateTime.now())) return false;
    return true;
  }

  /// Whether the user can still submit (or revise) an appeal.
  ///
  /// Conditions: suspension/ban, no final decision yet, within 14-day window.
  bool get canAppeal {
    if (type == SanctionType.warning) return false;
    if (appealDecision != null) return false;
    return DateTime.now().difference(createdAt).inDays < 14;
  }

  /// True when the user has submitted an appeal but no decision has been made.
  bool get isAppealPending => appealedAt != null && appealDecision == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SanctionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
