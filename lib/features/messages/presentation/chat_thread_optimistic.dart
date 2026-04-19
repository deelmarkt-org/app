import 'dart:async';

import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_type.dart';
import 'package:deelmarkt/features/messages/domain/entities/offer_status.dart';
import 'package:deelmarkt/features/messages/domain/repositories/message_repository.dart';

/// Optimistic-message factories for the chat thread (P-36).
///
/// Extracted from [ChatThreadNotifier] so the notifier file stays
/// under the 150-line viewmodel limit (CLAUDE.md §2.1) and so
/// optimistic message construction is unit-testable in isolation.
abstract final class ChatThreadOptimistic {
  /// Builds an optimistic plain-text message.
  static MessageEntity buildTextMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) {
    final now = DateTime.now();
    return MessageEntity(
      id: '_optimistic_${now.microsecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: senderId,
      text: text,
      createdAt: now,
    );
  }

  /// Builds an optimistic offer message. The displayed price uses two
  /// decimals so the bubble matches the formatter the EF returns.
  static MessageEntity buildOfferMessage({
    required String conversationId,
    required String senderId,
    required int amountCents,
  }) {
    final now = DateTime.now();
    return MessageEntity(
      id: '_optimistic_${now.microsecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: senderId,
      text: (amountCents / 100).toStringAsFixed(2),
      type: MessageType.offer,
      offerAmountCents: amountCents,
      offerStatus: OfferStatus.pending,
      createdAt: now,
    );
  }

  /// Logs the failure path of an optimistic send. Pulled out so the
  /// notifier doesn't repeat the AppLogger call shape inline.
  static void logSendFailure({
    required String message,
    required Object error,
    required StackTrace stackTrace,
  }) {
    AppLogger.error(
      message,
      tag: 'ChatThreadNotifier',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Subscribes to the realtime message stream for [conversationId]
  /// and forwards snapshots to [onSnapshot]. Errors go through
  /// [logSendFailure] with a fixed `watchMessages error` message so the
  /// notifier doesn't have to redeclare that boilerplate.
  static StreamSubscription<List<MessageEntity>> subscribeRealtime({
    required MessageRepository repository,
    required String conversationId,
    required void Function(List<MessageEntity>) onSnapshot,
  }) {
    return repository
        .watchMessages(conversationId)
        .listen(
          onSnapshot,
          onError:
              (Object e, StackTrace st) => logSendFailure(
                message: 'watchMessages error',
                error: e,
                stackTrace: st,
              ),
        );
  }

  /// Returns a copy of [messages] with the matching [messageId]
  /// updated to [newStatus]. Used by `updateOfferStatus` to apply
  /// optimistic offer-status changes without inlining the loop in
  /// the notifier.
  static List<MessageEntity> withOfferStatus(
    List<MessageEntity> messages, {
    required String messageId,
    required OfferStatus newStatus,
  }) {
    return [
      for (final msg in messages)
        if (msg.id == messageId) msg.copyWith(offerStatus: newStatus) else msg,
    ];
  }
}
