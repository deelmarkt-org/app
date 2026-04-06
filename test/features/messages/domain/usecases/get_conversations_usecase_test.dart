import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/domain/usecases/get_conversations_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fake_message_repository.dart';

void main() {
  ConversationEntity conv(String id, DateTime last) => ConversationEntity(
    id: id,
    listingId: 'listing-$id',
    listingTitle: 'Listing $id',
    listingImageUrl: null,
    otherUserId: 'user-$id',
    otherUserName: 'User $id',
    lastMessageText: 'hello',
    lastMessageAt: last,
  );

  test('returns conversations sorted by lastMessageAt descending', () async {
    final older = conv('a', DateTime(2026, 3, 20));
    final newer = conv('b', DateTime(2026, 3, 25));
    final middle = conv('c', DateTime(2026, 3, 22));
    final repo = FakeMessageRepository(conversations: [older, newer, middle]);

    final usecase = GetConversationsUseCase(repo);
    final result = await usecase();

    expect(result.map((c) => c.id).toList(), ['b', 'c', 'a']);
  });

  test('returns empty list when repository has no conversations', () async {
    final repo = FakeMessageRepository();
    final usecase = GetConversationsUseCase(repo);
    final result = await usecase();
    expect(result, isEmpty);
  });

  test('does not mutate the repository result', () async {
    final a = conv('a', DateTime(2026, 3, 20));
    final b = conv('b', DateTime(2026, 3, 25));
    final repo = FakeMessageRepository(conversations: [a, b]);
    final usecase = GetConversationsUseCase(repo);

    await usecase();
    final original = await repo.getConversations();

    expect(original.map((c) => c.id).toList(), ['a', 'b']);
  });
}
