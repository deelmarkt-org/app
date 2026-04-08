import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_type.dart';
import 'package:deelmarkt/features/messages/domain/entities/offer_status.dart';
import 'package:deelmarkt/features/messages/presentation/chat_thread_providers.dart';
import 'package:deelmarkt/features/messages/presentation/chat_thread_state.dart';
import 'package:deelmarkt/features/messages/presentation/conversation_list_notifier.dart';

export 'package:deelmarkt/features/messages/presentation/chat_thread_providers.dart'
    show kCurrentUserIdStub;
export 'package:deelmarkt/features/messages/presentation/chat_thread_state.dart';

part 'chat_thread_notifier.g.dart';

/// Async view-model for the chat thread screen (P-36).
/// Subscribes to Realtime updates; optimistic send rolls back on failure.
@riverpod
class ChatThreadNotifier extends _$ChatThreadNotifier {
  StreamSubscription<List<MessageEntity>>? _realtimeSub;
  List<MessageEntity>? _pendingSnapshot;

  @override
  Future<ChatThreadState> build(String conversationId) async {
    ref.onDispose(() => _realtimeSub?.cancel());

    final results = await Future.wait([
      ref.read(getConversationsUseCaseProvider)(),
      ref.read(getMessagesUseCaseProvider)(conversationId),
    ]);
    final conversations = results[0] as List<ConversationEntity>;
    final messages = results[1] as List<MessageEntity>;

    final conversation = conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => unknownConversationSentinel(conversationId),
    );

    _subscribeRealtime(conversationId);
    return ChatThreadState(conversation: conversation, messages: messages);
  }

  void _subscribeRealtime(String conversationId) {
    _realtimeSub?.cancel();
    _realtimeSub = ref
        .read(messageRepositoryProvider)
        .watchMessages(conversationId)
        .listen(
          (messages) {
            final current = state.valueOrNull;
            if (current == null) return;
            if (current.isSending) {
              _pendingSnapshot = messages;
            } else {
              state = AsyncValue.data(current.copyWith(messages: messages));
            }
          },
          onError:
              (Object e, StackTrace st) => AppLogger.error(
                'watchMessages error',
                tag: 'ChatThreadNotifier',
                error: e,
                stackTrace: st,
              ),
        );
  }

  Future<void> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _optimisticSend(
      optimistic: MessageEntity(
        id: '_optimistic_${DateTime.now().microsecondsSinceEpoch}',
        conversationId: state.valueOrNull?.conversation.id ?? '',
        senderId: kCurrentUserIdStub,
        text: trimmed,
        createdAt: DateTime.now(),
      ),
      send:
          (convId) => ref.read(sendMessageUseCaseProvider)(
            conversationId: convId,
            text: trimmed,
          ),
      tag: 'sendText',
    );
  }

  Future<void> sendOffer(int amountCents) async {
    final offerText = (amountCents / 100).toStringAsFixed(2);
    await _optimisticSend(
      optimistic: MessageEntity(
        id: '_optimistic_${DateTime.now().microsecondsSinceEpoch}',
        conversationId: state.valueOrNull?.conversation.id ?? '',
        senderId: kCurrentUserIdStub,
        text: offerText,
        type: MessageType.offer,
        offerAmountCents: amountCents,
        offerStatus: OfferStatus.pending,
        createdAt: DateTime.now(),
      ),
      send:
          (convId) => ref.read(sendMessageUseCaseProvider)(
            conversationId: convId,
            text: offerText,
            type: MessageType.offer,
            offerAmountCents: amountCents,
          ),
      tag: 'sendOffer',
    );
  }

  /// Updates the offer status with optimistic UI — the offer card shows the
  /// new status immediately and rolls back if the server call fails.
  Future<void> updateOfferStatus(
    String messageId,
    OfferStatus newStatus,
  ) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Optimistic: update the matching message's offerStatus
    final updatedMessages = [
      for (final msg in current.messages)
        if (msg.id == messageId)
          msg.copyWith(offerStatus: newStatus)
        else
          msg,
    ];
    state = AsyncValue.data(current.copyWith(messages: updatedMessages));

    try {
      await ref.read(updateOfferStatusUseCaseProvider)(
        messageId: messageId,
        newStatus: newStatus,
      );
    } catch (e, st) {
      AppLogger.error(
        'updateOfferStatus',
        tag: 'ChatThreadNotifier',
        error: e,
        stackTrace: st,
      );
      // Rollback to original messages
      state = AsyncValue.data(current.copyWith(messages: current.messages));
      rethrow;
    }
  }

  Future<void> _optimisticSend({
    required MessageEntity optimistic,
    required Future<MessageEntity> Function(String convId) send,
    required String tag,
  }) async {
    final current = state.valueOrNull;
    if (current == null || current.isSending) return;
    state = AsyncValue.data(
      current.copyWith(
        messages: [...current.messages, optimistic],
        isSending: true,
      ),
    );
    try {
      final sent = await send(current.conversation.id);
      final after = _pendingSnapshot ?? [...current.messages, sent];
      _pendingSnapshot = null;
      state = AsyncValue.data(
        current.copyWith(messages: after, isSending: false),
      );
    } catch (e, st) {
      AppLogger.error(tag, tag: 'ChatThreadNotifier', error: e, stackTrace: st);
      final after = _pendingSnapshot ?? current.messages;
      _pendingSnapshot = null;
      state = AsyncValue.data(
        current.copyWith(messages: after, isSending: false),
      );
      rethrow;
    }
  }
}
