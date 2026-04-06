import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';

void main() {
  final now = DateTime(2026, 3, 25, 14);

  group('MessageEntity', () {
    test('creates with required fields', () {
      final msg = MessageEntity(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        text: 'Hello',
        createdAt: now,
      );

      expect(msg.id, 'msg-1');
      expect(msg.conversationId, 'conv-1');
      expect(msg.senderId, 'user-1');
      expect(msg.text, 'Hello');
      expect(msg.type, MessageType.text);
      expect(msg.isRead, false);
      expect(msg.createdAt, now);
    });

    test('equality based on all props', () {
      final a = MessageEntity(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        text: 'Hello',
        createdAt: now,
      );
      final b = MessageEntity(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        text: 'Hello',
        createdAt: now,
      );
      final c = MessageEntity(
        id: 'msg-2',
        conversationId: 'conv-1',
        senderId: 'user-1',
        text: 'Hello',
        createdAt: now,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('different type makes unequal', () {
      final a = MessageEntity(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        text: 'offer',
        type: MessageType.offer,
        offerAmountCents: 1000,
        createdAt: now,
      );
      final b = MessageEntity(
        id: 'msg-1',
        conversationId: 'conv-1',
        senderId: 'user-1',
        text: 'offer',
        createdAt: now,
      );

      expect(a, isNot(equals(b)));
    });
  });

  group('MessageType', () {
    test('has all expected values', () {
      expect(
        MessageType.values,
        containsAll([
          MessageType.text,
          MessageType.offer,
          MessageType.systemAlert,
          MessageType.scamWarning,
        ]),
      );
    });
  });
}
