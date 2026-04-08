import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/messages/data/dto/conversation_dto.dart';
import 'package:deelmarkt/features/messages/data/dto/message_dto.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_type.dart';
import 'package:deelmarkt/features/messages/domain/entities/offer_status.dart';
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
  Future<List<MessageEntity>> getMessages(String conversationId) async {
    try {
      final response = await _client
          .from(_messagesTable)
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at');
      return MessageDto.fromJsonList(response as List<dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch messages: ${e.message}');
    }
  }

  @override
  Stream<List<MessageEntity>> watchMessages(String conversationId) {
    late StreamController<List<MessageEntity>> controller;
    RealtimeChannel? channel;

    controller = StreamController<List<MessageEntity>>(
      onListen: () async {
        if (!await _emitSnapshot(conversationId, controller)) return;
        channel = _subscribeChanges(conversationId, controller);
      },
      onCancel: () {
        channel?.unsubscribe();
        controller.close();
      },
    );

    return controller.stream;
  }

  /// Fetches the current message list and pushes it onto [controller].
  /// Returns `false` if an error occurred and was forwarded to the controller.
  Future<bool> _emitSnapshot(
    String conversationId,
    StreamController<List<MessageEntity>> controller,
  ) async {
    try {
      final messages = await getMessages(conversationId);
      if (!controller.isClosed) controller.add(messages);
      return true;
    } on Exception catch (e) {
      if (!controller.isClosed) controller.addError(e);
      return false;
    }
  }

  /// Subscribes to INSERT and UPDATE events for [conversationId] and
  /// re-emits a full snapshot on each event. UPDATE is required so that
  /// offer_status changes (accept/decline via R-32 RPC) are reflected
  /// in real-time without a manual refresh.
  RealtimeChannel _subscribeChanges(
    String conversationId,
    StreamController<List<MessageEntity>> controller,
  ) {
    final filter = PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'conversation_id',
      value: conversationId,
    );
    void onEvent(_) => _emitSnapshot(conversationId, controller);
    return _client
        .channel('$_channelPrefix$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: _messagesTable,
          filter: filter,
          callback: onEvent,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: _messagesTable,
          filter: filter,
          callback: onEvent,
        )
        .subscribe();
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
  Future<void> updateOfferStatus({
    required String messageId,
    required OfferStatus newStatus,
  }) async {
    if (newStatus != OfferStatus.accepted &&
        newStatus != OfferStatus.declined) {
      throw ArgumentError.value(
        newStatus,
        'newStatus',
        'Only accepted or declined are valid transitions',
      );
    }
    try {
      await _client.rpc(
        'update_offer_status',
        params: {'p_message_id': messageId, 'p_new_status': newStatus.toDb()},
      );
    } on PostgrestException catch (e) {
      throw Exception('Failed to update offer status: ${e.message}');
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
