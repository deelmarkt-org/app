import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';

void main() {
  group('ConversationEntity', () {
    test('equality by id', () {
      final a = ConversationEntity(
        id: 'c1',
        listingId: 'l1',
        listingTitle: 'A',
        listingImageUrl: null,
        otherUserId: 'u1',
        otherUserName: 'Alice',
        lastMessageText: 'Hi',
        lastMessageAt: DateTime(2026, 1, 1),
      );
      final b = ConversationEntity(
        id: 'c1',
        listingId: 'l2',
        listingTitle: 'B',
        listingImageUrl: null,
        otherUserId: 'u2',
        otherUserName: 'Bob',
        lastMessageText: 'Bye',
        lastMessageAt: DateTime(2026, 6, 1),
      );

      expect(a, equals(b));
    });

    test('default unreadCount is 0', () {
      final conv = ConversationEntity(
        id: 'c1',
        listingId: 'l1',
        listingTitle: 'Test',
        listingImageUrl: null,
        otherUserId: 'u1',
        otherUserName: 'User',
        lastMessageText: 'Hi',
        lastMessageAt: DateTime(2026, 1, 1),
      );

      expect(conv.unreadCount, equals(0));
    });
  });

  group('MessageEntity', () {
    test('equality by id', () {
      final a = MessageEntity(
        id: 'm1',
        conversationId: 'c1',
        senderId: 'u1',
        text: 'Hello',
        createdAt: DateTime(2026, 1, 1),
      );
      final b = MessageEntity(
        id: 'm1',
        conversationId: 'c2',
        senderId: 'u2',
        text: 'Different',
        createdAt: DateTime(2026, 6, 1),
      );

      expect(a, equals(b));
    });

    test('default type is text', () {
      final msg = MessageEntity(
        id: 'm1',
        conversationId: 'c1',
        senderId: 'u1',
        text: 'Hi',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(msg.type, equals(MessageType.text));
    });

    test('default isRead is false', () {
      final msg = MessageEntity(
        id: 'm1',
        conversationId: 'c1',
        senderId: 'u1',
        text: 'Hi',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(msg.isRead, isFalse);
    });
  });

  group('MessageType', () {
    test('has 4 types', () {
      expect(MessageType.values.length, equals(4));
    });

    test('contains scamWarning', () {
      expect(MessageType.values, contains(MessageType.scamWarning));
    });
  });
}
