/// Chat conversation between buyer and seller about a listing.
///
/// Immutable value object — domain layer, no Flutter/Supabase imports.
///
/// Reference: docs/epics/E04-messaging.md
class ConversationEntity {
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
  bool operator ==(Object other) =>
      identical(this, other) || other is ConversationEntity && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Single message in a conversation.
class MessageEntity {
  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.type = MessageType.text,
    this.isRead = false,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final MessageType type;
  final bool isRead;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MessageEntity && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Message types — per design system patterns.md §Chat.
enum MessageType { text, offer, systemAlert, scamWarning }
