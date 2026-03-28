import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/message_repository.dart';

/// Mock data constants to avoid duplicate literals.
const _currentUserId = 'user-001';
const _convId001 = 'conv-001';

/// Mock message repository — returns static data for Phase 1-2 widget development.
class MockMessageRepository implements MessageRepository {
  @override
  Future<List<ConversationEntity>> getConversations() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _mockConversations;
  }

  @override
  Future<List<MessageEntity>> getMessages(String conversationId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _mockMessages
        .where((m) => m.conversationId == conversationId)
        .toList();
  }

  @override
  Future<MessageEntity> sendMessage({
    required String conversationId,
    required String text,
    MessageType type = MessageType.text,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return MessageEntity(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: _currentUserId,
      text: text,
      type: type,
      createdAt: DateTime.now(),
    );
  }
}

final _mockConversations = [
  ConversationEntity(
    id: _convId001,
    listingId: 'listing-002',
    listingTitle: 'iPhone 15 Pro 256GB',
    listingImageUrl: 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
    otherUserId: 'user-002',
    otherUserName: 'Maria Jansen',
    lastMessageText: 'Is de prijs bespreekbaar?',
    lastMessageAt: DateTime(2026, 3, 25, 14, 30),
    unreadCount: 1,
  ),
  ConversationEntity(
    id: 'conv-002',
    listingId: 'listing-003',
    listingTitle: 'IKEA Kallax Kast 4x4',
    listingImageUrl: 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
    otherUserId: 'user-003',
    otherUserName: 'Pieter Bakker',
    lastMessageText: 'Kan ik morgen ophalen?',
    lastMessageAt: DateTime(2026, 3, 24, 10, 15),
    unreadCount: 0,
  ),
];

final _mockMessages = [
  MessageEntity(
    id: 'msg-001',
    conversationId: _convId001,
    senderId: _currentUserId,
    text: 'Hoi, ik heb interesse in de iPhone. Is deze nog beschikbaar?',
    createdAt: DateTime(2026, 3, 25, 14, 0),
    isRead: true,
  ),
  MessageEntity(
    id: 'msg-002',
    conversationId: _convId001,
    senderId: 'user-002',
    text: 'Ja, nog beschikbaar! Wil je hem zien?',
    createdAt: DateTime(2026, 3, 25, 14, 15),
    isRead: true,
  ),
  MessageEntity(
    id: 'msg-003',
    conversationId: _convId001,
    senderId: _currentUserId,
    text: 'Is de prijs bespreekbaar?',
    createdAt: DateTime(2026, 3, 25, 14, 30),
    isRead: false,
  ),
];
