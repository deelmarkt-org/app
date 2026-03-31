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
        lastMessageAt: DateTime(2026),
      );
      final b = ConversationEntity(
        id: 'c1',
        listingId: 'l1',
        listingTitle: 'A',
        listingImageUrl: null,
        otherUserId: 'u1',
        otherUserName: 'Alice',
        lastMessageText: 'Hi',
        lastMessageAt: DateTime(2026),
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
        lastMessageAt: DateTime(2026),
      );
      final b = ConversationEntity(
        id: 'c1',
        listingId: 'l1',
        listingTitle: 'A',
        listingImageUrl: null,
        otherUserId: 'u1',
        otherUserName: 'Alice',
        lastMessageText: 'Hi',
        lastMessageAt: DateTime(2026),
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
        lastMessageAt: DateTime(2026),
      );

      expect(conv.unreadCount, equals(0));
    });
  });

  // MessageEntity tests moved to message_entity_test.dart — avoid duplication
  // caused by conversation_entity.dart re-export (now removed).
}
