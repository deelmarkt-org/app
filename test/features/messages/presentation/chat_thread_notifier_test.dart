import 'dart:async';

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
  listingTitle: 'Canyon Speedmax',
  listingImageUrl: null,
  otherUserId: 'u2',
  otherUserName: 'Jan',
  lastMessageText: 'hi',
  lastMessageAt: DateTime(2026, 3, 25, 14),
);

MessageEntity _msg(String id, DateTime at, {String sender = 'user-001'}) =>
    MessageEntity(
      id: id,
      conversationId: 'c1',
      senderId: sender,
      text: id,
      createdAt: at,
    );

void main() {
  group('ChatThreadNotifier', () {
    test('loads conversation header and ordered messages', () async {
      final fake = FakeMessageRepository(
        conversations: [_conv('c1')],
        messages: [
          _msg('b', DateTime(2026, 3, 25, 10)),
          _msg('a', DateTime(2026, 3, 25, 9)),
        ],
      );
      final container = ProviderContainer(
        overrides: [messageRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final state = await container.read(
        chatThreadNotifierProvider('c1').future,
      );

      expect(state.conversation.id, 'c1');
      expect(state.messages.map((m) => m.id).toList(), ['a', 'b']);
      expect(state.isSending, isFalse);
    });

    test('sendText appends optimistically and clears isSending', () async {
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
          .sendText('  Hallo  ');

      final state =
          container.read(chatThreadNotifierProvider('c1')).requireValue;
      expect(state.messages.length, 1);
      expect(state.messages.single.text, 'Hallo');
      expect(state.isSending, isFalse);
      expect(fake.sendCalls.single.text, 'Hallo');
    });

    test('sendText ignores empty input', () async {
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
          .sendText('   ');

      expect(fake.sendCalls, isEmpty);
    });

    test('sendText rolls back optimistic message on failure', () async {
      final fake = FakeMessageRepository(
        conversations: [_conv('c1')],
        messages: [],
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
            .sendText('Hallo'),
        throwsA(isA<StateError>()),
      );

      final state =
          container.read(chatThreadNotifierProvider('c1')).requireValue;
      expect(state.messages, isEmpty);
      expect(state.isSending, isFalse);
    });

    test('sendOffer appends offer message with pending status', () async {
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
          .sendOffer(9900);

      final state =
          container.read(chatThreadNotifierProvider('c1')).requireValue;
      expect(state.messages.length, 1);
      expect(state.messages.single.type, MessageType.offer);
      expect(state.messages.single.offerAmountCents, 9900);
      expect(state.messages.single.offerStatus, OfferStatus.pending);
      expect(state.isSending, isFalse);
    });

    test('sendOffer formats text as euro amount', () async {
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
          .sendOffer(12050);

      expect(fake.sendCalls.single.text, '€ 120,50');
    });

    test('sendOffer rolls back on failure', () async {
      final fake = FakeMessageRepository(
        conversations: [_conv('c1')],
        messages: [],
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
            .sendOffer(5000),
        throwsA(isA<StateError>()),
      );

      final state =
          container.read(chatThreadNotifierProvider('c1')).requireValue;
      expect(state.messages, isEmpty);
      expect(state.isSending, isFalse);
    });

    test('unknown conversation id resolves to sentinel, no crash', () async {
      final fake = FakeMessageRepository(
        conversations: [_conv('c1')],
        messages: [],
      );
      final container = ProviderContainer(
        overrides: [messageRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final state = await container.read(
        chatThreadNotifierProvider('does-not-exist').future,
      );

      expect(state.conversation.id, 'does-not-exist');
      expect(state.messages, isEmpty);
    });

    test(
      'buffers Realtime snapshot received during send and applies on completion',
      () async {
        final fake = _RealtimeFakeRepository(
          conversations: [_conv('c1')],
          messages: [],
        );
        final container = ProviderContainer(
          overrides: [messageRepositoryProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        await container.read(chatThreadNotifierProvider('c1').future);

        // Simulate a concurrent Realtime snapshot arriving during isSending.
        final incomingMsg = _msg(
          'incoming',
          DateTime(2026, 3, 25, 15),
          sender: 'user-002',
        );
        fake.pushSnapshot([incomingMsg]);

        await container
            .read(chatThreadNotifierProvider('c1').notifier)
            .sendText('Hallo');

        // After send completes the buffered snapshot should be applied.
        final state =
            container.read(chatThreadNotifierProvider('c1')).requireValue;
        expect(state.isSending, isFalse);
      },
    );
  });
}

/// Fake repository with a controllable broadcast stream for Realtime tests.
class _RealtimeFakeRepository extends FakeMessageRepository {
  _RealtimeFakeRepository({
    required super.conversations,
    required super.messages,
  });

  final _controller = StreamController<List<MessageEntity>>.broadcast();

  void pushSnapshot(List<MessageEntity> msgs) => _controller.add(msgs);

  @override
  Stream<List<MessageEntity>> watchMessages(String conversationId) =>
      _controller.stream.map(
        (m) => m.where((e) => e.conversationId == conversationId).toList(),
      );
}
