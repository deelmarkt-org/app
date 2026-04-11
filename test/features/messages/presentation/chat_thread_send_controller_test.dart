import 'dart:async';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_type.dart';
import 'package:deelmarkt/features/messages/domain/entities/offer_status.dart';
import 'package:deelmarkt/features/messages/domain/repositories/message_repository.dart';
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

    // Regression test for the most fragile path in ChatThreadSendController:
    // when a Realtime snapshot arrives mid-send, the controller must stash
    // it on `pendingSnapshot` and apply it at send-completion — otherwise
    // server updates that land between the optimistic write and the final
    // writeState would be silently dropped.
    //
    // The notifier's `_subscribeRealtime` callback writes to
    // `_send.pendingSnapshot` directly when `state.isSending` is true
    // (see chat_thread_notifier.dart). This test drives that path via a
    // controllable fake repo whose `sendMessage` blocks on a `Completer`
    // the test completes manually.
    test(
      'applies pendingSnapshot arriving mid-send after send completes',
      () async {
        final sendCompleter = Completer<MessageEntity>();
        final realtimeController = StreamController<List<MessageEntity>>();
        final initial = _msg('existing');
        final fake = _ControllableRepository(
          conversations: [_conv('c1')],
          initialMessages: [initial],
          sendCompleter: sendCompleter,
          realtimeStream: realtimeController.stream,
        );
        addTearDown(realtimeController.close);

        final container = ProviderContainer(
          overrides: [messageRepositoryProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        // Keep the auto-dispose notifier alive for the whole test. Without
        // this listen(), the provider gets flagged for disposal after the
        // initial read(...future) and `valueOrNull` reads on the next tick
        // hit a disposed element.
        container.listen(
          chatThreadNotifierProvider('c1'),
          (_, _) {},
          fireImmediately: true,
        );

        // Prime the notifier. The initial watchMessages() emit is the
        // `[existing]` list from the fake; after this await the notifier
        // state contains exactly one message.
        await container.read(chatThreadNotifierProvider('c1').future);

        // Start a send — this schedules the optimistic write (appends
        // '_optimistic_*' to messages and flips isSending=true), then
        // awaits the sendCompleter which won't complete until we tell it to.
        final sendFuture = container
            .read(chatThreadNotifierProvider('c1').notifier)
            .sendText('hello');

        // Give the microtask queue a chance to apply the optimistic write
        // and reach the `await send(current.conversation.id)` line.
        await Future<void>.delayed(Duration.zero);

        final midSendState =
            container.read(chatThreadNotifierProvider('c1')).valueOrNull!;
        expect(
          midSendState.isSending,
          isTrue,
          reason: 'optimistic write should have set isSending=true',
        );
        expect(
          midSendState.messages.any((m) => m.text == 'hello'),
          isTrue,
          reason: 'optimistic hello should be in the list',
        );

        // Push a Realtime snapshot that contains a NEW server message
        // the optimistic list doesn't know about. The notifier's
        // watchMessages listener sees isSending=true and stashes this
        // on pendingSnapshot instead of writing it to state.
        final serverExtra = _msg('server-extra');
        realtimeController.add([initial, serverExtra]);

        // Let the stream callback run so the snapshot actually lands
        // on pendingSnapshot.
        await Future<void>.delayed(Duration.zero);

        // State should still be the optimistic one — the snapshot was
        // stashed, not applied.
        final stillMidSend =
            container.read(chatThreadNotifierProvider('c1')).valueOrNull!;
        expect(
          stillMidSend.messages.any((m) => m.id == 'server-extra'),
          isFalse,
          reason:
              'pending snapshot must NOT overwrite state while isSending=true',
        );

        // Complete the send — the controller drains pendingSnapshot and
        // applies it as the new messages list, dropping the optimistic
        // placeholder in favour of the server truth.
        sendCompleter.complete(
          MessageEntity(
            id: 'msg-sent',
            conversationId: 'c1',
            senderId: 'user-001',
            text: 'hello',
            createdAt: DateTime(2026, 4, 1, 12),
          ),
        );
        await sendFuture;

        // Final state = the drained pendingSnapshot ([initial, server-extra]),
        // NOT [initial, optimistic, sent] and NOT [initial, sent]. This
        // is the whole point of the pendingSnapshot dance: once the send
        // lands, trust the server truth over the local optimistic list.
        final finalState =
            container.read(chatThreadNotifierProvider('c1')).valueOrNull!;
        expect(finalState.isSending, isFalse);
        expect(finalState.messages.map((m) => m.id).toList(), [
          'existing',
          'server-extra',
        ]);
      },
    );
  });
}

/// Test-only [MessageRepository] that lets the test control when
/// `sendMessage` resolves and what `watchMessages` emits, so we can drive
/// the `pendingSnapshot` interplay in ChatThreadSendController
/// deterministically.
class _ControllableRepository implements MessageRepository {
  _ControllableRepository({
    required this.conversations,
    required this.initialMessages,
    required this.sendCompleter,
    required this.realtimeStream,
  });

  final List<ConversationEntity> conversations;
  final List<MessageEntity> initialMessages;
  final Completer<MessageEntity> sendCompleter;
  final Stream<List<MessageEntity>> realtimeStream;

  @override
  Future<List<ConversationEntity>> getConversations() async => conversations;

  @override
  Future<List<MessageEntity>> getMessages(
    String conversationId, {
    int? limit,
    int? offset,
  }) async => initialMessages;

  @override
  Stream<List<MessageEntity>> watchMessages(String conversationId) async* {
    // First yield the initial list so the notifier's `_subscribeRealtime`
    // has a snapshot to work with, then forward anything the test pushes.
    yield initialMessages;
    yield* realtimeStream;
  }

  @override
  Future<MessageEntity> sendMessage({
    required String conversationId,
    required String text,
    MessageType type = MessageType.text,
    int? offerAmountCents,
  }) => sendCompleter.future;

  @override
  Future<String> getOrCreateConversation({
    required String listingId,
    required String buyerId,
  }) async => 'conv-fake-001';

  @override
  Future<void> updateOfferStatus({
    required String messageId,
    required OfferStatus newStatus,
  }) async {}
}
