import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/messages/data/mock/mock_message_repository.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';

void main() {
  late MockMessageRepository repo;

  setUp(() {
    repo = MockMessageRepository();
  });

  group('MockMessageRepository', () {
    test('getConversations returns non-empty list', () async {
      final conversations = await repo.getConversations();

      expect(conversations, isNotEmpty);
      expect(conversations.first.id, isNotEmpty);
      expect(conversations.first.otherUserName, isNotEmpty);
    });

    test('getMessages returns messages for valid conversation', () async {
      final conversations = await repo.getConversations();
      final messages = await repo.getMessages(conversations.first.id);

      expect(messages, isNotEmpty);
      for (final msg in messages) {
        expect(msg.conversationId, conversations.first.id);
      }
    });

    test('getMessages returns empty for unknown conversation', () async {
      final messages = await repo.getMessages('unknown-conv');

      expect(messages, isEmpty);
    });

    test('sendMessage returns a new message', () async {
      final msg = await repo.sendMessage(
        conversationId: 'conv-001',
        text: 'Test message',
      );

      expect(msg.text, 'Test message');
      expect(msg.conversationId, 'conv-001');
      expect(msg.type, MessageType.text);
    });

    test('sendMessage with custom type', () async {
      final msg = await repo.sendMessage(
        conversationId: 'conv-001',
        text: '€45.00',
        type: MessageType.offer,
      );

      expect(msg.type, MessageType.offer);
    });
  });
}
