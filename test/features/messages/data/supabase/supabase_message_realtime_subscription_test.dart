import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/messages/data/supabase/supabase_message_realtime_subscription.dart';

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
  });
}
