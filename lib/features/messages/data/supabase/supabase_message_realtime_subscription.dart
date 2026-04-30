import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';

/// Extracted Realtime subscription helper for
/// [SupabaseMessageRepository.watchMessages] (B-64 — Tier-1 retrospective
/// decomposition; mirrors P-54 pattern).
///
/// Owns the lifecycle of a per-conversation `RealtimeChannel`:
///   1. Subscribe to INSERT + UPDATE postgres-changes for that conversation.
///   2. Emit a current snapshot via [snapshotLoader].
///   3. Re-emit a fresh snapshot on each event (sequence-tagged so a slow
///      earlier snapshot can never overwrite a fresher one — observed under
///      rapid updates that fan out multiple in-flight `_emitSnapshot`s).
///   4. Tear down channel + close controller on `onCancel`, awaiting the
///      `unsubscribe()` future so cleanup is properly sequenced.
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
    var seq = 0;
    var lastEmitted = 0;

    Future<void> emitSnapshot() async {
      // Sequence-tag every in-flight snapshot — gemini PR #268 medium
      // finding: under rapid updates an earlier `_snapshotLoader` future
      // may resolve AFTER a later one. Without this counter, the slow
      // response would overwrite the fresher snapshot in the stream and
      // surface stale data. Only emit if our seq is strictly newer than
      // anything already on the wire.
      final mine = ++seq;
      try {
        final messages = await _snapshotLoader(conversationId);
        if (controller.isClosed) return;
        if (mine <= lastEmitted) return;
        lastEmitted = mine;
        controller.add(messages);
      }
      // Catch Object (gemini PR #268 medium finding): an `Error` like a
      // TypeError during DTO parsing would bypass `on Exception` and crash
      // the subscription silently. Pipe every failure through addError
      // so the listener observes it.
      // ignore: avoid_catches_without_on_clauses
      catch (err) {
        if (!controller.isClosed) controller.addError(err);
      }
    }

    controller = StreamController<List<MessageEntity>>(
      onListen: () async {
        // Subscribe BEFORE the initial snapshot fetch (gemini PR #268
        // medium finding): events that fire during the snapshot await
        // would otherwise be missed. Subscribing first means any change
        // landing mid-fetch triggers a fresh `emitSnapshot`, and the
        // sequence guard above ensures the fresher snapshot wins.
        channel = _subscribeChanges(conversationId, emitSnapshot);
        await emitSnapshot();
      },
      onCancel: () async {
        // Await the `unsubscribe()` future (gemini PR #268 medium
        // finding): the controller awaits onCancel's completion before
        // the stream contract reports closed, so the websocket is torn
        // down deterministically before downstream cleanup proceeds.
        await channel?.unsubscribe();
        await controller.close();
      },
    );

    return controller.stream;
  }

  /// Subscribes to INSERT + UPDATE events for the given conversation,
  /// re-emitting a full snapshot on each event.
  RealtimeChannel _subscribeChanges(
    String conversationId,
    Future<void> Function() onChange,
  ) {
    final filter = PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: _conversationIdCol,
      value: conversationId,
    );
    void onEvent(_) {
      // Fire-and-forget — onChange handles its own errors and is
      // sequence-tagged so we never need to await per-event here.
      unawaited(onChange());
    }

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
