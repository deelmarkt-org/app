import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/usecases/send_message_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fake_message_repository.dart';

void main() {
  test('sends a trimmed message through the repository', () async {
    final repo = FakeMessageRepository();
    final usecase = SendMessageUseCase(repo);

    final result = await usecase(
      conversationId: 'conv-001',
      text: '  Hallo wereld  ',
    );

    expect(result.text, 'Hallo wereld');
    expect(repo.sendCalls, hasLength(1));
    expect(repo.sendCalls.single.conversationId, 'conv-001');
  });

  test('throws ArgumentError on empty text', () async {
    final repo = FakeMessageRepository();
    final usecase = SendMessageUseCase(repo);

    expect(
      () => usecase(conversationId: 'conv-001', text: '   '),
      throwsArgumentError,
    );
    expect(repo.sendCalls, isEmpty);
  });

  test('forwards the message type to the repository', () async {
    final repo = FakeMessageRepository();
    final usecase = SendMessageUseCase(repo);

    await usecase(
      conversationId: 'conv-001',
      text: 'Bod: € 35,00',
      type: MessageType.offer,
    );

    expect(repo.sendCalls.single.type, MessageType.offer);
  });

  test('propagates repository failures', () async {
    final repo = FakeMessageRepository(throwOnSend: true);
    final usecase = SendMessageUseCase(repo);

    expect(
      () => usecase(conversationId: 'conv-001', text: 'hi'),
      throwsA(isA<StateError>()),
    );
  });
}
