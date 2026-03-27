import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';

void main() {
  group('ConversationEntity', () {
    test('equality when all fields match', () {
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
        listingId: 'l1',
        listingTitle: 'A',
        listingImageUrl: null,
        otherUserId: 'u1',
        otherUserName: 'Alice',
        lastMessageText: 'Hi',
        lastMessageAt: DateTime(2026, 1, 1),
      );

      expect(a, equals(b));
    });

    test('inequality when fields differ (Riverpod state diffing)', () {
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
        listingId: 'l1',
        listingTitle: 'A',
        listingImageUrl: null,
        otherUserId: 'u1',
        otherUserName: 'Alice',
        lastMessageText: 'Hi',
        lastMessageAt: DateTime(2026, 1, 1),
        unreadCount: 3,
      );

      expect(a, isNot(equals(b)));
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
    test('equality when all fields match', () {
      final a = MessageEntity(
        id: 'm1',
        conversationId: 'c1',
        senderId: 'u1',
        text: 'Hello',
        createdAt: DateTime(2026, 1, 1),
      );
      final b = MessageEntity(
        id: 'm1',
        conversationId: 'c1',
        senderId: 'u1',
        text: 'Hello',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(a, equals(b));
    });

    test('inequality when fields differ', () {
      final a = MessageEntity(
        id: 'm1',
        conversationId: 'c1',
        senderId: 'u1',
        text: 'Hello',
        createdAt: DateTime(2026, 1, 1),
      );
      final b = MessageEntity(
        id: 'm1',
        conversationId: 'c1',
        senderId: 'u1',
        text: 'Hello',
        createdAt: DateTime(2026, 1, 1),
        isRead: true,
      );

      expect(a, isNot(equals(b)));
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
