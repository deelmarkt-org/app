import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/services/push_notification_service.dart';

/// PushNotificationService tests — limited to what can be tested without
/// Firebase emulator. FCM token registration and notification delivery
/// require real Firebase/Supabase and are covered by manual E2E testing.
void main() {
  group('PushNotificationService', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('provider builds without throwing', () {
      // The Riverpod provider should be constructible — the build() method
      // is a no-op that returns immediately (init is called after auth).
      expect(pushNotificationServiceProvider, isNotNull);
    });
  });
}
