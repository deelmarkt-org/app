import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/messages/data/dto/conversation_dto.dart';
import 'package:deelmarkt/features/messages/data/dto/message_dto.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_type.dart';
import 'package:deelmarkt/features/messages/domain/repositories/message_repository.dart';

/// Supabase implementation of [MessageRepository].
///
/// - REST queries via PostgREST for initial fetches.
/// - [watchMessages] uses a Supabase Realtime subscription on the `messages`
///   table filtered by `conversation_id`. On each INSERT event the full
///   message list is re-fetched so callers always receive an ordered, complete
///   snapshot (avoids ordering drift from out-of-order WebSocket delivery).
/// - [getConversations] calls the `get_conversations_for_user` RPC which
///   joins listings + user_profiles in one query (avoids N+1).
/// - [getOrCreateConversation] calls `get_or_create_conversation` RPC which
///   is idempotent (UPSERT with ON CONFLICT DO NOTHING).
///
/// Reference: docs/epics/E04-messaging.md §Supabase Realtime Messaging
class SupabaseMessageRepository implements MessageRepository {
  SupabaseMessageRepository(this._client);

  final SupabaseClient _client;

  static const _messagesTable = 'messages';
  static const _channelPrefix = 'messages:conv:';

  @override
  Future<List<ConversationEntity>> getConversations() async {
    try {
      final response = await _client.rpc('get_conversations_for_user');
      if (response == null) return [];
      return ConversationDto.fromJsonList(response as List<dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch conversations: ${e.message}');
    }
  }

  @override
  Future<List<MessageEntity>> getMessages(
    String conversationId, {
    int limit = 50,
    int? offset,
  }) async {
    try {
      var query = _client
          .from(_messagesTable)
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at');

      if (offset != null) {
        query = query.range(offset, offset + limit - 1);
      } else {
        query = query.limit(limit);
      }

      final response = await query;
      return MessageDto.fromJsonList(response as List<dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch messages: ${e.message}');
    }
  }

  @override
  Stream<List<MessageEntity>> watchMessages(String conversationId) {
    late StreamController<List<MessageEntity>> controller;
    RealtimeChannel? channel;

    /// Local cache of messages for delta updates.
    var messages = <MessageEntity>[];

    controller = StreamController<List<MessageEntity>>(
      onListen: () async {
        try {
          messages = await getMessages(conversationId);
          if (!controller.isClosed) controller.add(messages);
        } on Exception catch (e) {
          if (!controller.isClosed) controller.addError(e);
          return;
        }
        channel = _subscribeInserts(conversationId, controller, messages);
      },
      onCancel: () {
        channel?.unsubscribe();
        controller.close();
      },
    );

    return controller.stream;
  }

  /// Subscribes to INSERT events for [conversationId] and appends new
  /// messages from the Realtime payload instead of re-fetching all.
  /// Returns the active [RealtimeChannel].
  ///
  /// [messages] is the mutable local cache maintained across events.
  RealtimeChannel _subscribeInserts(
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
              final newRow = payload.newRecord;
              final newMessage = MessageDto.fromJson(newRow);
              // Avoid duplicates (idempotent handling).
              if (!messages.any((m) => m.id == newMessage.id)) {
                messages
                  ..add(newMessage)
                  ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
              }
              if (!controller.isClosed) {
                controller.add(List.unmodifiable(messages));
              }
            } on Object {
              // If payload parsing fails, fall back to full re-fetch.
              _fallbackRefetch(conversationId, controller, messages);
            }
          },
        )
        .subscribe();
  }

  /// Fallback: re-fetches all messages when a Realtime payload cannot be
  /// parsed. Keeps the stream alive instead of erroring out.
  Future<void> _fallbackRefetch(
    String conversationId,
    StreamController<List<MessageEntity>> controller,
    List<MessageEntity> messages,
  ) async {
    try {
      final refreshed = await getMessages(conversationId);
      messages
        ..clear()
        ..addAll(refreshed);
      if (!controller.isClosed) controller.add(List.unmodifiable(messages));
    } on Exception catch (e) {
      if (!controller.isClosed) controller.addError(e);
    }
  }

  @override
  Future<MessageEntity> sendMessage({
    required String conversationId,
    required String text,
    MessageType type = MessageType.text,
    int? offerAmountCents,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Cannot send message: user is not authenticated');
    }
    try {
      final response =
          await _client
              .from(_messagesTable)
              .insert(
                MessageDto.toInsertJson(
                  conversationId: conversationId,
                  senderId: userId,
                  text: text,
                  type: type,
                  offerAmountCents: offerAmountCents,
                ),
              )
              .select()
              .single();

      return MessageDto.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to send message: ${e.message}');
    }
  }

  @override
  Future<String> getOrCreateConversation({
    required String listingId,
    required String buyerId,
  }) async {
    try {
      final response = await _client.rpc(
        'get_or_create_conversation',
        params: {'p_listing_id': listingId, 'p_buyer_id': buyerId},
      );
      if (response == null) {
        throw Exception('get_or_create_conversation returned null');
      }
      return response as String;
    } on PostgrestException catch (e) {
      throw Exception('Failed to get or create conversation: ${e.message}');
    }
  }
}
