import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_type.dart';
import 'package:deelmarkt/features/messages/domain/entities/offer_status.dart';
import 'package:deelmarkt/features/messages/presentation/chat_thread_optimistic.dart';
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
    _realtimeSub = ChatThreadOptimistic.subscribeRealtime(
      repository: ref.read(messageRepositoryProvider),
      conversationId: conversationId,
      onSnapshot: (messages) {
        final current = state.valueOrNull;
        if (current == null) return;
        if (current.isSending) {
          _pendingSnapshot = messages;
        } else {
          state = AsyncValue.data(current.copyWith(messages: messages));
        }
      },
    );
  }

  Future<void> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final convId = state.valueOrNull?.conversation.id ?? '';
    await _optimisticSend(
      ChatThreadOptimistic.buildTextMessage(
        conversationId: convId,
        text: trimmed,
      ),
      (id) => ref.read(sendMessageUseCaseProvider)(
        conversationId: id,
        text: trimmed,
      ),
      'sendText',
    );
  }

  Future<void> sendOffer(int amountCents) async {
    final convId = state.valueOrNull?.conversation.id ?? '';
    final offerText = (amountCents / 100).toStringAsFixed(2);
    await _optimisticSend(
      ChatThreadOptimistic.buildOfferMessage(
        conversationId: convId,
        amountCents: amountCents,
      ),
      (id) => ref.read(sendMessageUseCaseProvider)(
        conversationId: id,
        text: offerText,
        type: MessageType.offer,
        offerAmountCents: amountCents,
      ),
      'sendOffer',
    );
  }

  /// Updates the offer status with optimistic UI — the offer card
  /// shows the new status immediately and rolls back if the server
  /// call fails.
  Future<void> updateOfferStatus(
    String messageId,
    OfferStatus newStatus,
  ) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(
      current.copyWith(
        messages: ChatThreadOptimistic.withOfferStatus(
          current.messages,
          messageId: messageId,
          newStatus: newStatus,
        ),
      ),
    );
    try {
      await ref.read(updateOfferStatusUseCaseProvider)(
        messageId: messageId,
        newStatus: newStatus,
      );
    } catch (e, st) {
      ChatThreadOptimistic.logSendFailure(
        tag: 'updateOfferStatus',
        error: e,
        stackTrace: st,
      );
      state = AsyncValue.data(current); // rollback
      rethrow;
    }
  }

  Future<void> _optimisticSend(
    MessageEntity optimistic,
    Future<MessageEntity> Function(String convId) send,
    String tag,
  ) async {
    final current = state.valueOrNull;
    if (current == null || current.isSending) return;
    state = AsyncValue.data(
      current.copyWith(
        messages: [...current.messages, optimistic],
        isSending: true,
      ),
    );
    List<MessageEntity> drainSnapshot(List<MessageEntity> fallback) {
      final after = _pendingSnapshot ?? fallback;
      _pendingSnapshot = null;
      return after;
    }

    try {
      final sent = await send(current.conversation.id);
      state = AsyncValue.data(
        current.copyWith(
          messages: drainSnapshot([...current.messages, sent]),
          isSending: false,
        ),
      );
    } catch (e, st) {
      ChatThreadOptimistic.logSendFailure(tag: tag, error: e, stackTrace: st);
      state = AsyncValue.data(
        current.copyWith(
          messages: drainSnapshot(current.messages),
          isSending: false,
        ),
      );
      rethrow;
    }
  }
}
