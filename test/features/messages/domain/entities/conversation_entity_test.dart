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

    test('lastMessageType defaults to null', () {
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

      expect(conv.lastMessageType, isNull);
    });

    test('lastMessageType is included in equality check', () {
      final base = ConversationEntity(
        id: 'c1',
        listingId: 'l1',
        listingTitle: 'A',
        listingImageUrl: null,
        otherUserId: 'u1',
        otherUserName: 'Alice',
        lastMessageText: '120.00',
        lastMessageAt: DateTime(2026),
      );
      final withType = base.copyWith(lastMessageType: 'offer');

      expect(base, isNot(equals(withType)));
      expect(withType.lastMessageType, 'offer');
    });

    test('copyWith preserves unspecified fields', () {
      final conv = ConversationEntity(
        id: 'c1',
        listingId: 'l1',
        listingTitle: 'A',
        listingImageUrl: 'img.jpg',
        otherUserId: 'u1',
        otherUserName: 'Alice',
        otherUserAvatarUrl: 'avatar.jpg',
        lastMessageText: 'Hi',
        lastMessageAt: DateTime(2026),
        lastMessageType: 'offer',
        unreadCount: 2,
        sellerResponseTimeMinutes: 45,
      );
      final copy = conv.copyWith(lastMessageText: 'Bye');

      expect(copy.id, conv.id);
      expect(copy.listingId, conv.listingId);
      expect(copy.otherUserAvatarUrl, conv.otherUserAvatarUrl);
      expect(copy.lastMessageType, conv.lastMessageType);
      expect(copy.unreadCount, conv.unreadCount);
      expect(copy.sellerResponseTimeMinutes, 45);
      expect(copy.lastMessageText, 'Bye');
    });

    test('sellerResponseTimeMinutes defaults to null', () {
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

      expect(conv.sellerResponseTimeMinutes, isNull);
    });

    test('sellerResponseTimeMinutes is included in equality check', () {
      final base = ConversationEntity(
        id: 'c1',
        listingId: 'l1',
        listingTitle: 'A',
        listingImageUrl: null,
        otherUserId: 'u1',
        otherUserName: 'Alice',
        lastMessageText: 'Hi',
        lastMessageAt: DateTime(2026),
      );
      final withTime = base.copyWith(sellerResponseTimeMinutes: 120);

      expect(base, isNot(equals(withTime)));
      expect(withTime.sellerResponseTimeMinutes, 120);
    });
  });

  // MessageEntity tests moved to message_entity_test.dart — avoid duplication
  // caused by conversation_entity.dart re-export (now removed).
}
