import 'package:equatable/equatable.dart';

/// Type of pending action for the seller.
enum ActionItemType {
  /// An order that needs to be shipped.
  shipOrder,

  /// A message that needs a reply.
  replyMessage,
}

/// A pending action requiring seller attention.
///
/// Displayed in the "Actie vereist" section of the seller home.
/// Extends [Equatable] for Riverpod state diffing (ADR-21).
///
/// Display strings (title, subtitle) are intentionally NOT stored here —
/// they are localisation concerns and are built in the presentation layer
/// using [type], [referenceId], [otherUserName], and [unreadCount].
class ActionItemEntity extends Equatable {
  const ActionItemEntity({
    required this.id,
    required this.type,
    required this.referenceId,
    this.otherUserName,
    this.unreadCount,
  });

  /// Unique identifier for this action item.
  final String id;

  /// Action type — determines icon, l10n template, and navigation target.
  final ActionItemType type;

  /// Reference to the related entity (transaction ID or conversation ID).
  final String referenceId;

  /// For [ActionItemType.replyMessage]: display name of the other participant.
  final String? otherUserName;

  /// For [ActionItemType.replyMessage]: number of unread messages.
  final int? unreadCount;

  @override
  List<Object?> get props => [
    id,
    type,
    referenceId,
    otherUserName,
    unreadCount,
  ];
}
