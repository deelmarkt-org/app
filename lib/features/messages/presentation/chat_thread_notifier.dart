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

/// Stub id for the current signed-in user.
///
/// TODO(auth): replace with `authStateProvider.currentUser.id` once the auth
/// subsystem ships via the `[R]` backend tasks. This single constant is the
/// source of truth for both the notifier (optimistic send sender) and the
/// screen (self vs other bubble alignment) — keep them in sync by importing
/// from here, never hardcoding the literal a second time.
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

  /// Subscribes to the repository Realtime stream. Incoming snapshots replace
  /// the messages list while preserving isSending state, so optimistic messages
  /// are not dropped mid-flight.
  void _subscribeRealtime(String conversationId) {
    _realtimeSub?.cancel();
    _realtimeSub = ref
        .read(messageRepositoryProvider)
        .watchMessages(conversationId)
        .listen(
          (messages) {
            final current = state.valueOrNull;
            if (current == null) return;
            // Only update if not mid-send to avoid clobbering optimistic UI.
            if (!current.isSending) {
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

  /// Optimistic send — appends the message to state immediately, then calls
  /// the repository. On failure, rolls back and surfaces the error.
  Future<void> sendText(String text) async {
    final current = state.valueOrNull;
    if (current == null || current.isSending) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // The `_optimistic_` prefix is a UI-only sentinel. SECURITY (F-05):
    // SupabaseMessageRepository MUST reject any client-supplied id starting
    // with `_optimistic_` to prevent the sentinel reaching the database.
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
      state = AsyncValue.data(
        current.copyWith(
          messages: [...current.messages, sent],
          isSending: false,
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'sendText failed',
        tag: 'ChatThreadNotifier',
        error: e,
        stackTrace: st,
      );
      state = AsyncValue.data(
        current.copyWith(messages: current.messages, isSending: false),
      );
      rethrow;
    }
  }
}
