import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';

/// Repository interface for account sanctions and appeal flow.
///
/// Reference: docs/epics/E06-trust-moderation.md §Account Suspension & Recovery
/// Reference: docs/SPRINT-PLAN.md R-37
abstract interface class SanctionRepository {
  /// Returns the current active suspension or ban for [userId], or null if
  /// none exists.
  ///
  /// Warnings and overturned sanctions are excluded. Delegates to the
  /// server-side [get_active_sanction] RPC (migration R-37) to avoid
  /// client-side clock manipulation.
  Future<SanctionEntity?> getActiveSanction(String userId);

  /// Returns full sanction history for [userId], newest first.
  Future<List<SanctionEntity>> getAll(String userId);

  /// Submits (or revises) an appeal for [sanctionId] with [appealBody].
  ///
  /// Idempotent: a second call updates the body as long as no moderator
  /// decision has been recorded yet.
  ///
  /// Throws if:
  /// - the sanction belongs to a different user
  /// - the sanction type is [SanctionType.warning]
  /// - the 14-day appeal window has closed
  /// - a final [AppealDecision] has already been issued
  Future<SanctionEntity> submitAppeal(String sanctionId, String appealBody);
}
