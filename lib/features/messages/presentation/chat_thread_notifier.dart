import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/usecases/get_messages_usecase.dart';
import 'package:deelmarkt/features/messages/domain/usecases/send_message_usecase.dart';
import 'package:deelmarkt/features/messages/presentation/conversation_list_notifier.dart';

part 'chat_thread_notifier.g.dart';

/// Stub id for the current signed-in user.
///
/// TODO(auth): replace with `authStateProvider.currentUser.id` once the auth
/// subsystem ships via the `[R]` backend tasks. This single constant is the
/// source of truth for both the notifier (optimistic send sender) and the
/// screen (self vs other bubble alignment) — keep them in sync by importing
/// from here, never hardcoding the literal a second time.
const String kCurrentUserIdStub = 'user-001';

/// Immutable state for a single chat thread.
class ChatThreadState extends Equatable {
  const ChatThreadState({
    required this.conversation,
    required this.messages,
    this.isSending = false,
  });

  final ConversationEntity conversation;
  final List<MessageEntity> messages;
  final bool isSending;

  ChatThreadState copyWith({
    ConversationEntity? conversation,
    List<MessageEntity>? messages,
    bool? isSending,
  }) {
    return ChatThreadState(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }

  @override
  List<Object?> get props => [conversation, messages, isSending];
}

final getMessagesUseCaseProvider = Provider<GetMessagesUseCase>(
  (ref) => GetMessagesUseCase(ref.watch(messageRepositoryProvider)),
);

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>(
  (ref) => SendMessageUseCase(ref.watch(messageRepositoryProvider)),
);
// Fallback when the conversation id in the URL cannot be resolved.
ConversationEntity _unknownConversation(String id) => ConversationEntity(
  id: id,
  listingId: '',
  listingTitle: '',
  listingImageUrl: null,
  otherUserId: '',
  otherUserName: '',
  lastMessageText: '',
  lastMessageAt: DateTime.fromMillisecondsSinceEpoch(0),
);

/// Async view-model for P-36. Loads conversation + messages in parallel;
/// supports optimistic send with rollback on failure.
@riverpod
class ChatThreadNotifier extends _$ChatThreadNotifier {
  @override
  Future<ChatThreadState> build(String conversationId) => _load(conversationId);

  Future<ChatThreadState> _load(String conversationId) async {
    final getConversations = ref.read(getConversationsUseCaseProvider);
    final getMessages = ref.read(getMessagesUseCaseProvider);

    final results = await Future.wait([
      getConversations(),
      getMessages(conversationId),
    ]);
    final conversations = results[0] as List<ConversationEntity>;
    final messages = results[1] as List<MessageEntity>;

    final conversation = conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => _unknownConversation(conversationId),
    );

    return ChatThreadState(conversation: conversation, messages: messages);
  }

  /// Optimistic send — appends the message to state immediately, then calls
  /// the repository. On failure, rolls back and surfaces the error.
  Future<void> sendText(String text) async {
    final current = state.valueOrNull;
    if (current == null || current.isSending) {
      return;
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    // SECURITY (F-05): prefix is a UI-only sentinel; server MUST reject
    // ids starting with `_optimistic_` (never persisted to the database).
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
      final sendMessage = ref.read(sendMessageUseCaseProvider);
      final sent = await sendMessage(
        conversationId: current.conversation.id,
        text: trimmed,
      );
      final updated = [...current.messages, sent];
      state = AsyncValue.data(
        current.copyWith(messages: updated, isSending: false),
      );
    } catch (e, st) {
      AppLogger.error(
        'sendText failed',
        tag: 'ChatThreadNotifier',
        error: e,
        stackTrace: st,
      );
      // Rollback: drop the optimistic message.
      state = AsyncValue.data(
        current.copyWith(messages: current.messages, isSending: false),
      );
      // Re-throw so the UI can show a SnackBar via ref.listen.
      rethrow;
    }
  }
}
