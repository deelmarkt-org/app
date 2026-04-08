import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/messages/data/dto/message_dto.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';

/// Handles Supabase Realtime subscriptions for a single conversation.
///
/// Extracted from [SupabaseMessageRepository] to keep the repository
/// focused on CRUD operations (CLAUDE.md §2.1, 200-line limit).
///
/// On each INSERT event the new message is appended from the Realtime
/// payload. If parsing fails, falls back to a full re-fetch so the
/// stream stays alive.
class MessageRealtimeHandler {
  MessageRealtimeHandler({
    required SupabaseClient client,
    required Future<List<MessageEntity>> Function(String, {int? limit}) fetcher,
  }) : _client = client,
       _fetcher = fetcher;

  final SupabaseClient _client;
  final Future<List<MessageEntity>> Function(String, {int? limit}) _fetcher;

  static const _messagesTable = 'messages';
  static const _channelPrefix = 'messages:conv:';

  /// Subscribes to INSERT events for [conversationId] and appends new
  /// messages from the Realtime payload instead of re-fetching all.
  ///
  /// [messages] is the immutable-style local cache maintained across events.
  /// [controller] receives updated snapshots.
  RealtimeChannel subscribe(
    String conversationId,
    StreamController<List<MessageEntity>> controller,
    List<MessageEntity> messages,
  ) {
    return _client
        .channel('$_channelPrefix$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: _messagesTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            try {
              final newMessage = MessageDto.fromJson(payload.newRecord);
              if (!messages.any((m) => m.id == newMessage.id)) {
                messages = [...messages, newMessage]
                  ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
              }
              if (!controller.isClosed) {
                controller.add(List.unmodifiable(messages));
              }
            } on Exception {
              _fallbackRefetch(conversationId, controller, messages);
            }
          },
        )
        .subscribe();
  }

  /// Re-fetches messages when a Realtime payload cannot be parsed.
  /// Uses the current cache size as the limit to avoid truncation.
  Future<void> _fallbackRefetch(
    String conversationId,
    StreamController<List<MessageEntity>> controller,
    List<MessageEntity> messages,
  ) async {
    try {
      final refreshed = await _fetcher(
        conversationId,
        limit: messages.length.clamp(50, 500),
      );
      messages
        ..clear()
        ..addAll(refreshed);
      if (!controller.isClosed) controller.add(List.unmodifiable(messages));
    } on Exception catch (e) {
      if (!controller.isClosed) controller.addError(e);
    }
  }
}
