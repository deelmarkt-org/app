import 'package:equatable/equatable.dart';

/// Chat conversation between buyer and seller about a listing.
///
/// Immutable value object — domain layer, no Flutter/Supabase imports.
/// Extends [Equatable] for Riverpod state diffing (ADR-21).
///
/// Reference: docs/epics/E04-messaging.md
class ConversationEntity extends Equatable {
  const ConversationEntity({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.listingImageUrl,
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessageText,
    required this.lastMessageAt,
    this.otherUserAvatarUrl,
    this.unreadCount = 0,
  });

  final String id;
  final String listingId;
  final String listingTitle;
  final String? listingImageUrl;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatarUrl;
  final String lastMessageText;
  final DateTime lastMessageAt;
  final int unreadCount;

  @override
  List<Object?> get props => [
    id,
    listingId,
    listingTitle,
    listingImageUrl,
    otherUserId,
    otherUserName,
    otherUserAvatarUrl,
    lastMessageText,
    lastMessageAt,
    unreadCount,
  ];
}
