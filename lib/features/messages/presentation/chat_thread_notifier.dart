import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/offer_status.dart';
import 'package:deelmarkt/features/messages/presentation/chat_thread_optimistic.dart';
import 'package:deelmarkt/features/messages/presentation/chat_thread_providers.dart';
import 'package:deelmarkt/features/messages/presentation/chat_thread_send_controller.dart';
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
  late final ChatThreadSendController _send = ChatThreadSendController(
    ref: ref,
    getState: () => state.valueOrNull,
    writeState: (s) => state = AsyncValue.data(s),
  );
  StreamSubscription<List<MessageEntity>>? _realtimeSub;

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
              _send.pendingSnapshot = messages;
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

  Future<void> sendText(String text) => _send.sendText(text);

  Future<void> sendOffer(int amountCents) => _send.sendOffer(amountCents);

  Future<void> updateOfferStatus(String messageId, OfferStatus newStatus) =>
      _send.updateOfferStatus(messageId, newStatus);
}
