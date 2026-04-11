/// What type of content is being reported.
/// Matches the `dsa_target_t` DB enum (migration R-38).
enum DsaTargetType { listing, message, profile, review }

/// DSA Art. 16 notice category.
/// Matches the `dsa_category_t` DB enum (migration R-38).
enum DsaReportCategory {
  illegalContent,
  prohibitedItem,
  counterfeit,
  fraud,
  privacyViolation,
  other,
}

/// Lifecycle status of a DSA notice-and-action report.
/// Matches the `dsa_status_t` DB enum (migration R-38).
enum DsaReportStatus { pending, underReview, actioned, rejected }

/// A user-filed DSA notice-and-action report against platform content.
///
/// The 24-hour SLA is tracked server-side via [slaDeadline].
/// [isSlaBreached] is a UI hint only — the authoritative overdue query is the
/// server-side `get_overdue_dsa_reports()` RPC (used by the admin dashboard).
///
/// Reference: docs/epics/E06-trust-moderation.md §DSA Transparency Module
/// Reference: docs/SPRINT-PLAN.md R-38
class DsaReportEntity {
  const DsaReportEntity({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.category,
    required this.description,
    required this.reportedAt,
    required this.slaDeadline,
    required this.status,
    this.reporterId,
    this.reviewedBy,
    this.reviewedAt,
    this.resolutionNotes,
  });

  final String id;
  final String? reporterId;
  final DsaTargetType targetType;
  final String targetId;
  final DsaReportCategory category;
  final String description;
  final DateTime reportedAt;

  /// Server-set to `reported_at + 24 hours`.
  final DateTime slaDeadline;

  final DsaReportStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? resolutionNotes;

  /// UI hint: SLA has passed and report is still open.
  /// The authoritative check is `get_overdue_dsa_reports()` (service_role).
  bool get isSlaBreached =>
      DateTime.now().isAfter(slaDeadline) &&
      (status == DsaReportStatus.pending ||
          status == DsaReportStatus.underReview);

  bool get isOpen =>
      status == DsaReportStatus.pending ||
      status == DsaReportStatus.underReview;

  bool get isClosed =>
      status == DsaReportStatus.actioned || status == DsaReportStatus.rejected;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DsaReportEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
