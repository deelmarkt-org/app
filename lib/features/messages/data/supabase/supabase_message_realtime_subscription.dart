import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';

/// Extracted Realtime subscription helper for
/// [SupabaseMessageRepository.watchMessages] (B-64 — Tier-1 retrospective
/// decomposition; mirrors P-54 pattern).
///
/// Owns the lifecycle of a per-conversation `RealtimeChannel`:
///   1. Emit a current snapshot via [snapshotLoader].
///   2. Subscribe to INSERT + UPDATE postgres-changes for that conversation.
///   3. Re-emit a fresh snapshot on each event.
///   4. Tear down channel + close controller on `onCancel`.
///
/// The repository injects the snapshot loader so this helper has no
/// knowledge of the underlying `getMessages` query. Pure orchestration.
///
/// Reference: docs/epics/E04-messaging.md §Supabase Realtime Messaging
class SupabaseMessageRealtimeSubscription {
  SupabaseMessageRealtimeSubscription({
    required SupabaseClient client,
    required String messagesTable,
    required String conversationIdCol,
    required String channelPrefix,
    required Future<List<MessageEntity>> Function(String conversationId)
    snapshotLoader,
  }) : _client = client,
       _messagesTable = messagesTable,
       _conversationIdCol = conversationIdCol,
       _channelPrefix = channelPrefix,
       _snapshotLoader = snapshotLoader;

  final SupabaseClient _client;
  final String _messagesTable;
  final String _conversationIdCol;
  final String _channelPrefix;
  final Future<List<MessageEntity>> Function(String conversationId)
  _snapshotLoader;

  /// Returns a broadcast-able stream of [MessageEntity] snapshots for the
  /// given [conversationId]. The stream emits an initial snapshot then a
  /// fresh snapshot on every INSERT or UPDATE postgres-change event.
  Stream<List<MessageEntity>> watch(String conversationId) {
    late StreamController<List<MessageEntity>> controller;
    RealtimeChannel? channel;

    controller = StreamController<List<MessageEntity>>(
      onListen: () async {
        if (!await _emitSnapshot(conversationId, controller)) return;
        // Listener may have cancelled while _emitSnapshot was awaiting; without
        // this guard _subscribeChanges would create a RealtimeChannel that
        // onCancel can no longer unsubscribe (channel was still null when it
        // ran), leaking a Supabase websocket subscription.
        if (controller.isClosed) return;
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
      final messages = await _snapshotLoader(conversationId);
      if (!controller.isClosed) controller.add(messages);
      return true;
    } on Exception catch (e) {
      if (!controller.isClosed) controller.addError(e);
      return false;
    }
  }

  /// Subscribes to INSERT + UPDATE events for the given conversation,
  /// re-emitting a full snapshot on each event.
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
}
