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
/// Display strings are NOT stored here. Instead, [params] holds structured
/// key/value data that the presentation layer passes to `.tr(namedArgs:)`
/// to render localised text from the `admin.activity.<type>` l10n keys.
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class ActivityItemEntity extends Equatable {
  const ActivityItemEntity({
    required this.id,
    required this.type,
    required this.params,
    required this.timestamp,
  });

  /// Unique identifier for this activity item.
  final String id;

  /// Category of admin event — determines the l10n key used for display.
  final ActivityItemType type;

  /// Structured parameters passed to `.tr(namedArgs: params)`.
  ///
  /// Keys are domain-specific identifiers (e.g. `listingId`, `moderator`,
  /// `userId`, `version`). Values are plain strings without localisation.
  final Map<String, String> params;

  /// When this event occurred.
  final DateTime timestamp;

  @override
  List<Object?> get props => [id, type, params, timestamp];
}
