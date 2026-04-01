import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';

/// Message repository interface — domain layer.
abstract class MessageRepository {
  /// Get all conversations for the current user.
  Future<List<ConversationEntity>> getConversations();

  /// Get messages in a conversation.
  Future<List<MessageEntity>> getMessages(String conversationId);

  /// Send a message.
  Future<MessageEntity> sendMessage({
    required String conversationId,
    required String text,
    MessageType type = MessageType.text,
  });
}
