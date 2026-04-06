import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/presentation/conversation_list_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/usecases/_fake_message_repository.dart';

ConversationEntity _conv(String id, DateTime at) => ConversationEntity(
  id: id,
  listingId: 'listing-$id',
  listingTitle: 'Listing $id',
  listingImageUrl: null,
  otherUserId: 'user-$id',
  otherUserName: 'User $id',
  lastMessageText: 'hi',
  lastMessageAt: at,
);

void main() {
  group('ConversationListNotifier', () {
    test('loading → data', () async {
      final fake = FakeMessageRepository(
        conversations: [
          _conv('a', DateTime(2026, 3, 20)),
          _conv('b', DateTime(2026, 3, 25)),
        ],
      );
      final container = ProviderContainer(
        overrides: [messageRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      // First read is AsyncLoading.
      expect(
        container.read(conversationListNotifierProvider),
        const AsyncLoading<List<ConversationEntity>>(),
      );

      final data = await container.read(
        conversationListNotifierProvider.future,
      );
      expect(data.map((c) => c.id).toList(), ['b', 'a']);
    });

    test('loading → error when repository throws', () async {
      final throwing = _ThrowingRepository();
      final container = ProviderContainer(
        overrides: [messageRepositoryProvider.overrideWithValue(throwing)],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(conversationListNotifierProvider.future),
        throwsA(isA<StateError>()),
      );
      expect(container.read(conversationListNotifierProvider).hasError, isTrue);
    });

    test('refresh() re-fetches and transitions through loading', () async {
      final fake = FakeMessageRepository(
        conversations: [_conv('a', DateTime(2026, 3, 20))],
      );
      final container = ProviderContainer(
        overrides: [messageRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      await container.read(conversationListNotifierProvider.future);
      await container.read(conversationListNotifierProvider.notifier).refresh();

      final data = await container.read(
        conversationListNotifierProvider.future,
      );
      expect(data.single.id, 'a');
    });
  });
}

class _ThrowingRepository extends FakeMessageRepository {
  @override
  Future<List<ConversationEntity>> getConversations() async {
    throw StateError('boom');
  }
}
