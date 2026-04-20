import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_type.dart';
import 'package:deelmarkt/features/messages/domain/entities/offer_status.dart';
import 'package:deelmarkt/features/messages/presentation/chat_thread_providers.dart';
import 'package:deelmarkt/features/messages/presentation/chat_thread_state.dart';

/// Controller that owns the optimistic-send logic for the chat thread.
///
/// Composed by [ChatThreadNotifier] so the notifier file stays under the
/// viewmodel line limit (CLAUDE.md §2.1). Receives state get/set callbacks
/// from the notifier — the lambdas are defined inside the notifier class so
/// the `state` setter is accessed from a permitted call site.
class ChatThreadSendController {
  ChatThreadSendController({
    required this.ref,
    required this.getState,
    required this.writeState,
  });

  final Ref ref;
  final ChatThreadState? Function() getState;

  /// Plain-state setter — accepts only completed [ChatThreadState] values.
  ///
  /// **Constraint:** Cannot emit `AsyncValue.loading` or `AsyncValue.error`
  /// directly. All inflight indicators and error surfaces must be managed by
  /// the enclosing [ChatThreadNotifier] via its own `state = AsyncValue.loading()`
  /// or `state = AsyncValue.error(e, st)` calls, not through this callback.
  ///
  /// **Why:** Keeps [ChatThreadSendController] testable in isolation — callers
  /// pass a simple `(s) => state = AsyncValue.data(s)` lambda without needing
  /// to expose the full `Notifier.state` setter.
  ///
  /// **Refactor trigger:** If a future task requires per-send loading
  /// indicators or realtime-disconnect banners surfaced *through* this
  /// controller, change the signature to
  /// `void Function(AsyncValue<ChatThreadState>)` and update all call sites.
  final void Function(ChatThreadState) writeState;

  /// Snapshot from realtime that arrived while a send was in flight; applied
  /// once the send completes (or rolls back) so we don't drop server updates.
  List<MessageEntity>? pendingSnapshot;

  Future<void> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final now = DateTime.now();
    await _optimisticSend(
      optimistic: MessageEntity(
        id: '_optimistic_${now.microsecondsSinceEpoch}',
        conversationId: getState()?.conversation.id ?? '',
        senderId: ref.read(currentUserProvider)?.id ?? '',
        text: trimmed,
        createdAt: now,
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
    final now = DateTime.now();
    await _optimisticSend(
      optimistic: MessageEntity(
        id: '_optimistic_${now.microsecondsSinceEpoch}',
        conversationId: getState()?.conversation.id ?? '',
        senderId: ref.read(currentUserProvider)?.id ?? '',
        text: offerText,
        type: MessageType.offer,
        offerAmountCents: amountCents,
        offerStatus: OfferStatus.pending,
        createdAt: now,
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
    final current = getState();
    if (current == null) return;

    final updatedMessages = [
      for (final msg in current.messages)
        if (msg.id == messageId) msg.copyWith(offerStatus: newStatus) else msg,
    ];
    writeState(current.copyWith(messages: updatedMessages));

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
      // Rollback: `current` was captured before the optimistic write, so
      // writing it back restores the pre-attempt state in one setter call.
      writeState(current);
      rethrow;
    }
  }

  Future<void> _optimisticSend({
    required MessageEntity optimistic,
    required Future<MessageEntity> Function(String convId) send,
    required String tag,
  }) async {
    final current = getState();
    if (current == null || current.isSending) return;
    writeState(
      current.copyWith(
        messages: [...current.messages, optimistic],
        isSending: true,
      ),
    );
    try {
      final sent = await send(current.conversation.id);
      final after = pendingSnapshot ?? [...current.messages, sent];
      pendingSnapshot = null;
      writeState(current.copyWith(messages: after, isSending: false));
    } catch (e, st) {
      AppLogger.error(tag, tag: 'ChatThreadNotifier', error: e, stackTrace: st);
      final after = pendingSnapshot ?? current.messages;
      pendingSnapshot = null;
      writeState(current.copyWith(messages: after, isSending: false));
      rethrow;
    }
  }
}
