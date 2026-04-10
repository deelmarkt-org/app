import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_type.dart';
import 'package:deelmarkt/features/messages/domain/entities/offer_status.dart';
import 'package:deelmarkt/features/messages/presentation/chat_thread_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/usecases/_fake_message_repository.dart';

ConversationEntity _conv(String id) => ConversationEntity(
  id: id,
  listingId: 'l1',
  listingTitle: 'Test Item',
  listingImageUrl: null,
  otherUserId: 'u2',
  otherUserName: 'Jan',
  lastMessageText: 'hi',
  lastMessageAt: DateTime(2026, 3, 25, 14),
);

MessageEntity _msg(String id) => MessageEntity(
  id: id,
  conversationId: 'c1',
  senderId: 'user-001',
  text: id,
  createdAt: DateTime(2026, 4),
);

void main() {
  group('ChatThreadSendController (via ChatThreadNotifier)', () {
    test('sendText appends message to state', () async {
      final fake = FakeMessageRepository(
        conversations: [_conv('c1')],
        messages: [_msg('existing')],
      );
      final container = ProviderContainer(
        overrides: [messageRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      await container.read(chatThreadNotifierProvider('c1').future);
      await container
          .read(chatThreadNotifierProvider('c1').notifier)
          .sendText('hello');

      final state =
          container.read(chatThreadNotifierProvider('c1')).valueOrNull!;
      expect(state.messages.any((m) => m.text == 'hello'), isTrue);
    });

    test('sendText rolls back optimistic message on failure', () async {
      final fake = FakeMessageRepository(
        conversations: [_conv('c1')],
        messages: [_msg('existing')],
        throwOnSend: true,
      );
      final container = ProviderContainer(
        overrides: [messageRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      await container.read(chatThreadNotifierProvider('c1').future);

      await expectLater(
        container
            .read(chatThreadNotifierProvider('c1').notifier)
            .sendText('fail'),
        throwsA(isA<StateError>()),
      );

      final state =
          container.read(chatThreadNotifierProvider('c1')).valueOrNull!;
      expect(state.messages.any((m) => m.text == 'fail'), isFalse);
      expect(state.isSending, isFalse);
    });

    test('sendOffer creates offer message with correct amount', () async {
      final fake = FakeMessageRepository(
        conversations: [_conv('c1')],
        messages: [],
      );
      final container = ProviderContainer(
        overrides: [messageRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      await container.read(chatThreadNotifierProvider('c1').future);
      await container
          .read(chatThreadNotifierProvider('c1').notifier)
          .sendOffer(2500);

      expect(fake.sendCalls.any((m) => m.offerAmountCents == 2500), isTrue);
      expect(fake.sendCalls.any((m) => m.type == MessageType.offer), isTrue);
    });

    test(
      'updateOfferStatus applies optimistic update and calls repo',
      () async {
        final offerMsg = MessageEntity(
          id: 'offer-1',
          conversationId: 'c1',
          senderId: 'u2',
          text: '25.00',
          type: MessageType.offer,
          offerAmountCents: 2500,
          offerStatus: OfferStatus.pending,
          createdAt: DateTime(2026, 4),
        );
        final fake = FakeMessageRepository(
          conversations: [_conv('c1')],
          messages: [offerMsg],
        );
        final container = ProviderContainer(
          overrides: [messageRepositoryProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        await container.read(chatThreadNotifierProvider('c1').future);
        await container
            .read(chatThreadNotifierProvider('c1').notifier)
            .updateOfferStatus('offer-1', OfferStatus.accepted);

        final state =
            container.read(chatThreadNotifierProvider('c1')).valueOrNull!;
        final updated = state.messages.firstWhere((m) => m.id == 'offer-1');
        expect(updated.offerStatus, OfferStatus.accepted);
      },
    );
  });
}
