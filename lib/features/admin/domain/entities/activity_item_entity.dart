import 'package:equatable/equatable.dart';

/// Type of admin activity event.
/// Reference: docs/screens/08-admin/01-admin-panel.md
enum ActivityItemType {
  listingRemoved,
  userVerified,
  disputeEscalated,
  systemUpdate,
}

/// A single entry in the admin activity feed.
///
/// Immutable value object — domain layer, no Flutter/Supabase imports.
/// Extends [Equatable] for Riverpod state diffing (ADR-21).
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class ActivityItemEntity extends Equatable {
  const ActivityItemEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });

  /// Unique identifier for this activity item.
  final String id;

  /// Category of admin event.
  final ActivityItemType type;

  /// Primary display text (e.g. "Listing #4321 verwijderd door Moderator A").
  final String title;

  /// Secondary display text with additional context.
  final String subtitle;

  /// When this event occurred.
  final DateTime timestamp;

  @override
  List<Object?> get props => [id, type, title, subtitle, timestamp];
}
