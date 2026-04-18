import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_type.dart';
import 'package:deelmarkt/features/messages/domain/entities/offer_status.dart';
import 'package:deelmarkt/features/messages/presentation/chat_thread_optimistic.dart';

import '../domain/usecases/_fake_message_repository.dart';

void main() {
  group('ChatThreadOptimistic.buildTextMessage', () {
    test('returns a text message tagged as optimistic', () {
      final msg = ChatThreadOptimistic.buildTextMessage(
        conversationId: 'conv-1',
        senderId: 'user-1',
        text: 'Hello',
      );
      expect(msg.conversationId, 'conv-1');
      expect(msg.text, 'Hello');
      expect(msg.id.startsWith('_optimistic_'), isTrue);
      expect(msg.type, MessageType.text);
      expect(msg.offerAmountCents, isNull);
      expect(msg.offerStatus, isNull);
    });
  });

  group('ChatThreadOptimistic.buildOfferMessage', () {
    test('formats the price with two decimals', () {
      final msg = ChatThreadOptimistic.buildOfferMessage(
        conversationId: 'conv-1',
        senderId: 'user-1',
        amountCents: 4500,
      );
      expect(msg.text, '45.00');
    });

    test('formats sub-euro amounts with leading zero', () {
      final msg = ChatThreadOptimistic.buildOfferMessage(
        conversationId: 'conv-1',
        senderId: 'user-1',
        amountCents: 50,
      );
      expect(msg.text, '0.50');
    });

    test('marks the message as a pending offer', () {
      final msg = ChatThreadOptimistic.buildOfferMessage(
        conversationId: 'conv-1',
        senderId: 'user-1',
        amountCents: 1234,
      );
      expect(msg.type, MessageType.offer);
      expect(msg.offerAmountCents, 1234);
      expect(msg.offerStatus, OfferStatus.pending);
      expect(msg.id.startsWith('_optimistic_'), isTrue);
    });
  });

  group('ChatThreadOptimistic.withOfferStatus', () {
    final messages = [
      MessageEntity(
        id: 'm1',
        conversationId: 'conv',
        senderId: 'u1',
        text: 'first',
        createdAt: DateTime(2026),
      ),
      MessageEntity(
        id: 'm2',
        conversationId: 'conv',
        senderId: 'u1',
        text: '4500',
        type: MessageType.offer,
        offerAmountCents: 4500,
        offerStatus: OfferStatus.pending,
        createdAt: DateTime(2026, 1, 2),
      ),
      MessageEntity(
        id: 'm3',
        conversationId: 'conv',
        senderId: 'u1',
        text: 'reply',
        createdAt: DateTime(2026, 1, 3),
      ),
    ];

    test('updates the matching message and leaves others untouched', () {
      final result = ChatThreadOptimistic.withOfferStatus(
        messages,
        messageId: 'm2',
        newStatus: OfferStatus.accepted,
      );
      expect(result, hasLength(3));
      expect(result[0].offerStatus, isNull);
      expect(result[1].offerStatus, OfferStatus.accepted);
      expect(result[2].offerStatus, isNull);
    });

    test('returns the input unchanged when the id is not found', () {
      final result = ChatThreadOptimistic.withOfferStatus(
        messages,
        messageId: 'nonexistent',
        newStatus: OfferStatus.declined,
      );
      expect(result, hasLength(3));
      expect(result[1].offerStatus, OfferStatus.pending);
    });

    test('handles an empty input list', () {
      final result = ChatThreadOptimistic.withOfferStatus(
        const [],
        messageId: 'm1',
        newStatus: OfferStatus.accepted,
      );
      expect(result, isEmpty);
    });
  });

  group('ChatThreadOptimistic.logSendFailure', () {
    test('runs without throwing for any error type', () {
      expect(
        () => ChatThreadOptimistic.logSendFailure(
          message: 'sendMessage',
          error: Exception('network timeout'),
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });
  });

  group('ChatThreadOptimistic.subscribeRealtime', () {
    test('forwards snapshots to the callback', () async {
      final repo = FakeMessageRepository(
        messages: [
          MessageEntity(
            id: 'msg-1',
            conversationId: 'conv-A',
            senderId: 'u1',
            text: 'hi',
            createdAt: DateTime(2026),
          ),
        ],
      );

      final received = <List<MessageEntity>>[];
      final sub = ChatThreadOptimistic.subscribeRealtime(
        repository: repo,
        conversationId: 'conv-A',
        onSnapshot: received.add,
      );

      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(received, hasLength(1));
      expect(received.first.first.id, 'msg-1');
    });

    test(
      'handles stream error via logSendFailure without rethrowing',
      () async {
        final controller = StreamController<List<MessageEntity>>();
        final errorRepo = _ErrorMessageRepository(controller.stream);

        final sub = ChatThreadOptimistic.subscribeRealtime(
          repository: errorRepo,
          conversationId: 'conv-err',
          onSnapshot: (_) {},
        );

        controller.addError(Exception('stream error'));
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();
        await controller.close();
        // No exception propagated — logSendFailure swallows it.
      },
    );
  });
}

/// Minimal MessageRepository that exposes a pre-built stream for error testing.
class _ErrorMessageRepository extends FakeMessageRepository {
  _ErrorMessageRepository(this._stream);
  final Stream<List<MessageEntity>> _stream;

  @override
  Stream<List<MessageEntity>> watchMessages(String conversationId) => _stream;
}
