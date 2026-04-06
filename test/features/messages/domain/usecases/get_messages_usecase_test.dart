import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/usecases/get_messages_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fake_message_repository.dart';

void main() {
  MessageEntity msg(
    String id,
    DateTime at, {
    String conversation = 'conv-001',
  }) => MessageEntity(
    id: id,
    conversationId: conversation,
    senderId: 'user-001',
    text: id,
    createdAt: at,
  );

  test('returns messages sorted oldest → newest', () async {
    final newer = msg('b', DateTime(2026, 3, 25, 10));
    final older = msg('a', DateTime(2026, 3, 25, 9));
    final newest = msg('c', DateTime(2026, 3, 25, 11));
    final repo = FakeMessageRepository(messages: [newer, older, newest]);

    final usecase = GetMessagesUseCase(repo);
    final result = await usecase('conv-001');

    expect(result.map((m) => m.id).toList(), ['a', 'b', 'c']);
  });

  test('filters messages by conversation id', () async {
    final repo = FakeMessageRepository(
      messages: [
        msg('a', DateTime(2026, 3, 25)),
        msg('b', DateTime(2026, 3, 25), conversation: 'conv-002'),
      ],
    );
    final usecase = GetMessagesUseCase(repo);
    final result = await usecase('conv-001');
    expect(result.map((m) => m.id).toList(), ['a']);
  });

  test('returns empty list for unknown conversation', () async {
    final repo = FakeMessageRepository();
    final usecase = GetMessagesUseCase(repo);
    final result = await usecase('nope');
    expect(result, isEmpty);
  });
}
