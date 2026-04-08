import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_type.dart';

/// Message repository interface — domain layer.
///
/// Provides both one-shot fetches and a Realtime stream for live updates.
/// The Supabase implementation wires [watchMessages] to a PostgreSQL
/// Realtime subscription; the mock implementation yields from a local list.
///
/// Reference: docs/epics/E04-messaging.md §Supabase Realtime Messaging
abstract class MessageRepository {
  /// Get all conversations for the current user, newest first.
  Future<List<ConversationEntity>> getConversations();

  /// Get messages in a conversation, oldest first.
  ///
  /// Supports optional pagination via [limit] and [offset].
  /// When [limit] is null all messages are returned (no truncation).
  ///
  // TODO(reso): wire limit/offset through GetMessagesUseCase and add
  // a loadMore() to ChatThreadNotifier — deelmarkt-org/app#80.
  Future<List<MessageEntity>> getMessages(
    String conversationId, {
    int? limit,
    int? offset,
  });

  /// Subscribe to new messages in a conversation via Supabase Realtime.
  ///
  /// Emits the full, up-to-date message list whenever a new message arrives.
  /// The stream completes when the caller cancels the subscription.
  Stream<List<MessageEntity>> watchMessages(String conversationId);

  /// Send a message in a conversation.
  Future<MessageEntity> sendMessage({
    required String conversationId,
    required String text,
    MessageType type = MessageType.text,
    int? offerAmountCents,
  });

  /// Get or create a conversation for [buyerId] about [listingId].
  ///
  /// Returns the conversation ID. Idempotent — calling twice returns the
  /// same conversation.
  Future<String> getOrCreateConversation({
    required String listingId,
    required String buyerId,
  });
}
