import 'package:equatable/equatable.dart';

/// Aggregate statistics for the admin dashboard overview.
///
/// Immutable value object — domain layer, no Flutter/Supabase imports.
/// Extends [Equatable] for Riverpod state diffing (ADR-21).
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class AdminStatsEntity extends Equatable {
  const AdminStatsEntity({
    required this.openDisputes,
    required this.dsaNoticesWithin24h,
    required this.activeListings,
    required this.escrowAmountCents,
    required this.flaggedListings,
    required this.reportedUsers,
    required this.approvedCount,
  });

  /// Number of unresolved disputes awaiting admin action.
  final int openDisputes;

  /// DSA Art. 16 notices received in the last 24 hours.
  final int dsaNoticesWithin24h;

  /// Total listings currently in 'active' status.
  final int activeListings;

  /// Total funds held in escrow, in cents (e.g. 1245000 = €12.450,00).
  final int escrowAmountCents;

  /// Listings flagged for review by users or automated filters.
  final int flaggedListings;

  /// Users reported by other users, pending moderation.
  final int reportedUsers;

  /// Listings approved by moderators (lifetime or period-scoped).
  final int approvedCount;

  @override
  List<Object?> get props => [
    openDisputes,
    dsaNoticesWithin24h,
    activeListings,
    escrowAmountCents,
    flaggedListings,
    reportedUsers,
    approvedCount,
  ];
}
