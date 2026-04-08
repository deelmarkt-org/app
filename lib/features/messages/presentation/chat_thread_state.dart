import 'package:equatable/equatable.dart';

import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';

/// Sentinel conversation used when the URL id cannot be resolved to a known
/// conversation (e.g. stale deep link). The screen renders gracefully rather
/// than crashing.
ConversationEntity unknownConversationSentinel(String id) => ConversationEntity(
  id: id,
  listingId: '',
  listingTitle: '',
  listingImageUrl: null,
  otherUserId: '',
  otherUserName: '',
  lastMessageText: '',
  lastMessageAt: DateTime.fromMillisecondsSinceEpoch(0),
);

/// Immutable state for a single chat thread.
class ChatThreadState extends Equatable {
  const ChatThreadState({
    required this.conversation,
    required this.messages,
    this.isSending = false,
  });

  final ConversationEntity conversation;
  final List<MessageEntity> messages;
  final bool isSending;

  ChatThreadState copyWith({
    ConversationEntity? conversation,
    List<MessageEntity>? messages,
    bool? isSending,
  }) {
    return ChatThreadState(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }

  @override
  List<Object?> get props => [conversation, messages, isSending];
}
