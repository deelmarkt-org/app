import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/usecases/get_messages_usecase.dart';
import 'package:deelmarkt/features/messages/domain/usecases/send_message_usecase.dart';
import 'package:deelmarkt/features/messages/presentation/chat_thread_state.dart';
import 'package:deelmarkt/features/messages/presentation/conversation_list_notifier.dart';

export 'package:deelmarkt/features/messages/presentation/chat_thread_state.dart';

part 'chat_thread_notifier.g.dart';

/// Stub user id while auth is unwired.
/// TODO(pizmam): replace with authStateProvider — deelmarkt-org/app#80.
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
    // Cancel any previous subscription when the provider is rebuilt or disposed.
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

    // Subscribe to Realtime after initial load to receive messages from
    // the other participant without polling.
    _subscribeRealtime(conversationId);

    return ChatThreadState(conversation: conversation, messages: messages);
  }

  /// Subscribes to the repository Realtime stream; buffers snapshots during
  /// isSending so optimistic messages are not dropped mid-flight.
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
              // Buffer snapshot — apply once send completes.
              _pendingSnapshot = messages;
            } else {
              state = AsyncValue.data(current.copyWith(messages: messages));
            }
          },
          onError: (Object e, StackTrace st) {
            AppLogger.error(
              'watchMessages error',
              tag: 'ChatThreadNotifier',
              error: e,
              stackTrace: st,
            );
          },
        );
  }

  /// Optimistic send — appends immediately; rolls back on failure.
  Future<void> sendText(String text) async {
    final current = state.valueOrNull;
    if (current == null || current.isSending) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // UI-only sentinel id — never persisted to the database.
    final optimistic = MessageEntity(
      id: '_optimistic_${DateTime.now().microsecondsSinceEpoch}',
      conversationId: current.conversation.id,
      senderId: kCurrentUserIdStub,
      text: trimmed,
      createdAt: DateTime.now(),
    );

    state = AsyncValue.data(
      current.copyWith(
        messages: [...current.messages, optimistic],
        isSending: true,
      ),
    );

    try {
      final sent = await ref.read(sendMessageUseCaseProvider)(
        conversationId: current.conversation.id,
        text: trimmed,
      );
      final after = _pendingSnapshot ?? [...current.messages, sent];
      _pendingSnapshot = null;
      state = AsyncValue.data(
        current.copyWith(messages: after, isSending: false),
      );
    } catch (e, st) {
      AppLogger.error(
        'sendText failed',
        tag: 'ChatThreadNotifier',
        error: e,
        stackTrace: st,
      );
      final after = _pendingSnapshot ?? current.messages;
      _pendingSnapshot = null;
      state = AsyncValue.data(
        current.copyWith(messages: after, isSending: false),
      );
      rethrow;
    }
  }
}
