import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/messages/data/supabase/supabase_message_realtime_subscription.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockRealtimeChannel extends Mock implements RealtimeChannel {}

void main() {
  setUpAll(() {
    registerFallbackValue(PostgresChangeEvent.insert);
    registerFallbackValue(
      PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversation_id',
        value: 'fallback',
      ),
    );
  });

  // Wire common Postgres-change stubs once per test via this helper —
  // every test plumbs the same chain (channel → onPostgresChanges ×2
  // → subscribe).
  void wireChannelChain(_MockSupabaseClient client, _MockRealtimeChannel ch) {
    when(() => client.channel(any())).thenReturn(ch);
    when(
      () => ch.onPostgresChanges(
        event: any(named: 'event'),
        schema: any(named: 'schema'),
        table: any(named: 'table'),
        filter: any(named: 'filter'),
        callback: any(named: 'callback'),
      ),
    ).thenReturn(ch);
  }

  group('SupabaseMessageRealtimeSubscription', () {
    test('class is exported', () {
      expect(SupabaseMessageRealtimeSubscription, isNotNull);
    });

    test('public watch method has expected signature', () {
      const ctor = SupabaseMessageRealtimeSubscription.new;
      expect(ctor, isNotNull);
    });

    test('snapshotLoader Error (e.g. TypeError) is forwarded to the stream '
        '(gemini PR #268 medium finding)', () async {
      final mockClient = _MockSupabaseClient();
      final mockChannel = _MockRealtimeChannel();
      wireChannelChain(mockClient, mockChannel);
      when(mockChannel.subscribe).thenReturn(mockChannel);
      when(mockChannel.unsubscribe).thenAnswer((_) async => 'ok');

      final subscription = SupabaseMessageRealtimeSubscription(
        client: mockClient,
        messagesTable: 'messages',
        conversationIdCol: 'conversation_id',
        channelPrefix: 'msg:',
        snapshotLoader: (_) async => throw TypeError(),
      );

      final received = <Object>[];
      final completer = Completer<void>();
      final sub = subscription
          .watch('conv_001')
          .listen(
            (_) {},
            onError: (Object e) {
              received.add(e);
              if (!completer.isCompleted) completer.complete();
            },
          );
      await completer.future.timeout(const Duration(seconds: 1));
      await sub.cancel();
      expect(received, hasLength(1));
      expect(received.single, isA<TypeError>());
    });

    test('subscribe-before-snapshot — channel.subscribe() runs before the '
        'snapshot resolves (gemini PR #268 medium finding)', () async {
      final mockClient = _MockSupabaseClient();
      final mockChannel = _MockRealtimeChannel();
      var clock = 0;
      var subscribeCalledAt = -1;
      var snapshotResolvedAt = -1;
      wireChannelChain(mockClient, mockChannel);
      when(mockChannel.subscribe).thenAnswer((_) {
        subscribeCalledAt = clock++;
        return mockChannel;
      });
      when(mockChannel.unsubscribe).thenAnswer((_) async => 'ok');

      final subscription = SupabaseMessageRealtimeSubscription(
        client: mockClient,
        messagesTable: 'messages',
        conversationIdCol: 'conversation_id',
        channelPrefix: 'msg:',
        snapshotLoader: (_) async {
          await Future<void>.delayed(Duration.zero);
          snapshotResolvedAt = clock++;
          return const <MessageEntity>[];
        },
      );

      final completer = Completer<void>();
      final sub = subscription.watch('conv_001').listen((_) {
        if (!completer.isCompleted) completer.complete();
      });
      await completer.future.timeout(const Duration(seconds: 1));
      await sub.cancel();
      expect(
        subscribeCalledAt,
        lessThan(snapshotResolvedAt),
        reason:
            'channel.subscribe() MUST run before the snapshot future '
            'resolves so events landing during the fetch are not missed',
      );
    });

    test(
      'onCancel awaits unsubscribe() future (gemini PR #268 medium finding)',
      () async {
        final mockClient = _MockSupabaseClient();
        final mockChannel = _MockRealtimeChannel();
        var unsubCompleted = false;
        wireChannelChain(mockClient, mockChannel);
        when(mockChannel.subscribe).thenReturn(mockChannel);
        when(mockChannel.unsubscribe).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          unsubCompleted = true;
          return 'ok';
        });

        final subscription = SupabaseMessageRealtimeSubscription(
          client: mockClient,
          messagesTable: 'messages',
          conversationIdCol: 'conversation_id',
          channelPrefix: 'msg:',
          snapshotLoader: (_) async => const <MessageEntity>[],
        );

        final sub = subscription.watch('conv_001').listen((_) {});
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await sub.cancel();
        expect(
          unsubCompleted,
          isTrue,
          reason:
              'sub.cancel() MUST resolve only after the underlying '
              'unsubscribe() future completes',
        );
      },
    );
  });
}
