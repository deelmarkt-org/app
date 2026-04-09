import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/messages/data/dto/conversation_dto.dart';
import 'package:deelmarkt/features/messages/data/dto/message_dto.dart';
import 'package:deelmarkt/features/messages/data/supabase/message_scam_scanner.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_type.dart';
import 'package:deelmarkt/features/messages/domain/entities/offer_status.dart';
import 'package:deelmarkt/features/messages/domain/repositories/message_repository.dart';

/// Supabase implementation of [MessageRepository].
/// Reference: docs/epics/E04-messaging.md §Supabase Realtime Messaging
class SupabaseMessageRepository implements MessageRepository {
  SupabaseMessageRepository(this._client)
      : _scamScanner = MessageScamScanner(_client);

  final SupabaseClient _client;
  final MessageScamScanner _scamScanner;

  static const _messagesTable = 'messages';
  static const _conversationIdCol = 'conversation_id';
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
    int? limit,
    int? offset,
  }) async {
    try {
      var query = _client
          .from(_messagesTable)
          .select()
          .eq(_conversationIdCol, conversationId)
          .order('created_at');

      if (limit != null) {
        if (offset != null) {
          query = query.range(offset, offset + limit - 1);
        } else {
          query = query.limit(limit);
        }
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

  /// Emits current messages onto [controller]. Returns false on error.
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

  /// Subscribes to INSERT + UPDATE events, re-emitting a full snapshot each time.
  RealtimeChannel _subscribeChanges(
    String conversationId,
    StreamController<List<MessageEntity>> controller,
  ) {
    final filter = PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: _conversationIdCol,
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

      final sentMessage = MessageDto.fromJson(response);
      _scamScanner.scan(sentMessage); // fire-and-forget R-35 scam check

      return sentMessage;
    } on PostgrestException catch (e) {
      throw Exception('Failed to send message: ${e.message}');
    }
  }

  @override
  Future<void> updateOfferStatus({
    required String messageId,
    required OfferStatus newStatus,
  }) async {
    if (newStatus != OfferStatus.accepted && newStatus != OfferStatus.declined) {
      throw ArgumentError.value(newStatus, 'newStatus', 'Only accepted or declined');
    }
    try {
      await _client.rpc('update_offer_status', params: {
        'p_message_id': messageId,
        'p_new_status': newStatus.toDb(),
      });
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
      final response = await _client.rpc('get_or_create_conversation', params: {
        'p_listing_id': listingId,
        'p_buyer_id': buyerId,
      });
      if (response == null) throw Exception('get_or_create_conversation returned null');
      return response as String;
    } on PostgrestException catch (e) {
      throw Exception('Failed to get or create conversation: ${e.message}');
    }
  }
}
