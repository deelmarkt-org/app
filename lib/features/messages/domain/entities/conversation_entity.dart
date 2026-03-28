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

  ConversationEntity copyWith({
    String? id,
    String? listingId,
    String? listingTitle,
    String? listingImageUrl,
    String? otherUserId,
    String? otherUserName,
    String? otherUserAvatarUrl,
    String? lastMessageText,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) {
    return ConversationEntity(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      listingTitle: listingTitle ?? this.listingTitle,
      listingImageUrl: listingImageUrl ?? this.listingImageUrl,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatarUrl: otherUserAvatarUrl ?? this.otherUserAvatarUrl,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
