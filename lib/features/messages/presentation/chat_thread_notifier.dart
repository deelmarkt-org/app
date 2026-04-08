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

/// Stub id for the current signed-in user.
///
/// TODO(pizmam): replace with `authStateProvider.currentUser.id` once the auth
/// subsystem ships — tracked in deelmarkt-org/app#80 (R-13 / R-14).
/// This single constant is the source of truth for both the notifier
/// (optimistic send sender) and the screen (self vs other bubble alignment)
/// — keep them in sync by importing from here, never hardcoding the literal
/// a second time.
const String kCurrentUserIdStub = 'user-001';

/// DI — reuses the same use-case providers as the list notifier where possible.
final getMessagesUseCaseProvider = Provider<GetMessagesUseCase>(
  (ref) => GetMessagesUseCase(ref.watch(messageRepositoryProvider)),
);
final sendMessageUseCaseProvider = Provider<SendMessageUseCase>(
  (ref) => SendMessageUseCase(ref.watch(messageRepositoryProvider)),
);

/// Async view-model for the chat thread screen (P-36).
///
/// Loads the conversation header, then subscribes to [MessageRepository.watchMessages]
/// for real-time updates from the other participant. On each Realtime event the
/// repository re-fetches the full ordered list so local state stays consistent.
///
/// Optimistic send appends the message immediately; on failure it rolls back
/// and re-throws so the UI can show a SnackBar via ref.listen.
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
    final euros = (amountCents / 100).toStringAsFixed(2).replaceAll('.', ',');
    final offerText = '€ $euros';
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
