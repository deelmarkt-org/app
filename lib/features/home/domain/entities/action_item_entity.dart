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
class ActionItemEntity extends Equatable {
  const ActionItemEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.referenceId,
  });

  /// Unique identifier for this action item.
  final String id;

  /// Action type — determines icon and navigation target.
  final ActionItemType type;

  /// Primary label (e.g. "Verzend bestelling #1234").
  final String title;

  /// Secondary label (e.g. buyer name or message preview).
  final String subtitle;

  /// Reference to the related entity (transaction ID or conversation ID).
  final String referenceId;

  @override
  List<Object?> get props => [id, type, title, subtitle, referenceId];
}
