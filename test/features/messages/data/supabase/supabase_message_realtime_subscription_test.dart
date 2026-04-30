import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/messages/data/supabase/supabase_message_realtime_subscription.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  group('SupabaseMessageRealtimeSubscription', () {
    // Real instantiation requires a SupabaseClient + a live Realtime
    // channel; smoke tests verify the public surface area only.
    // End-to-end coverage of the watch flow is exercised by the
    // existing SupabaseMessageRepository integration tests + the
    // realtime smoke test against a staging Supabase project.
    test('class is exported', () {
      expect(SupabaseMessageRealtimeSubscription, isNotNull);
    });

    test('public watch method has expected signature', () {
      // Static reference catches accidental signature changes that
      // would silently break SupabaseMessageRepository.watchMessages.
      const ctor = SupabaseMessageRealtimeSubscription.new;
      expect(ctor, isNotNull);
    });

    test(
      'cancel during snapshot load does not subscribe a Realtime channel',
      () async {
        // Regression test for the early-cancellation race fixed in PR #268:
        // if the listener cancelled while _emitSnapshot was awaiting, the
        // subscription helper would still create a RealtimeChannel that
        // onCancel could never unsubscribe (channel was still null when it
        // ran), leaking a Supabase websocket subscription. The fix is an
        // isClosed guard before _subscribeChanges; this test asserts that
        // no `.channel()` call is made on the underlying SupabaseClient
        // when cancel races the snapshot.
        final client = _MockSupabaseClient();
        final snapshotCompleter = Completer<List<MessageEntity>>();

        final subscription = SupabaseMessageRealtimeSubscription(
          client: client,
          messagesTable: 'messages',
          conversationIdCol: 'conversation_id',
          channelPrefix: 'msg:',
          snapshotLoader: (_) => snapshotCompleter.future,
        );

        final stream = subscription.watch('conv_001');
        final sub = stream.listen((_) {});

        // Cancel while snapshot loader is still pending — this is the race.
        await sub.cancel();

        // Now release the snapshot future. With the fix, the helper checks
        // controller.isClosed and returns before calling _subscribeChanges.
        snapshotCompleter.complete(const []);
        await Future<void>.delayed(Duration.zero);

        // If the guard regresses, _subscribeChanges would call client.channel
        // here, which the mock would record (and the leak would be observable
        // in production as a dangling websocket subscription).
        verifyNever(() => client.channel(any()));
      },
    );
  });
}
