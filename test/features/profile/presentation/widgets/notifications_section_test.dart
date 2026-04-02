import 'package:deelmarkt/features/profile/domain/entities/notification_preferences.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/notifications_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('NotificationsSection', () {
    testWidgets('renders 4 SwitchListTile widgets', (tester) async {
      await pumpTestWidget(
        tester,
        NotificationsSection(
          prefs: const NotificationPreferences(),
          onChanged: (_) {},
        ),
      );

      expect(find.byType(SwitchListTile), findsNWidgets(4));
    });

    testWidgets('renders section header', (tester) async {
      await pumpTestWidget(
        tester,
        NotificationsSection(
          prefs: const NotificationPreferences(),
          onChanged: (_) {},
        ),
      );

      expect(find.text('settings.notifications'), findsOneWidget);
    });

    testWidgets('toggle fires onChanged with updated messages pref', (
      tester,
    ) async {
      NotificationPreferences? received;
      await pumpTestWidget(
        tester,
        NotificationsSection(
          prefs: const NotificationPreferences(),
          onChanged: (prefs) => received = prefs,
        ),
      );

      final switches = tester.widgetList<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      // First switch is messages — currently true, toggle to false
      final messagesSwitch = switches.first;
      expect(messagesSwitch.value, isTrue);

      // Tap the first switch
      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pumpAndSettle();

      expect(received, isNotNull);
      expect(received!.messages, isFalse);
      expect(received!.offers, isTrue);
      expect(received!.shippingUpdates, isTrue);
      expect(received!.marketing, isFalse);
    });

    testWidgets('toggle fires onChanged with updated marketing pref', (
      tester,
    ) async {
      NotificationPreferences? received;
      await pumpTestWidget(
        tester,
        NotificationsSection(
          prefs: const NotificationPreferences(),
          onChanged: (prefs) => received = prefs,
        ),
      );

      // Last switch is marketing — currently false, toggle to true
      await tester.tap(find.byType(SwitchListTile).last);
      await tester.pumpAndSettle();

      expect(received, isNotNull);
      expect(received!.marketing, isTrue);
    });

    testWidgets('reflects current preference values', (tester) async {
      await pumpTestWidget(
        tester,
        NotificationsSection(
          prefs: const NotificationPreferences(
            messages: false,
            offers: false,
            shippingUpdates: false,
            marketing: true,
          ),
          onChanged: (_) {},
        ),
      );

      final switches =
          tester
              .widgetList<SwitchListTile>(find.byType(SwitchListTile))
              .toList();

      expect(switches[0].value, isFalse); // messages
      expect(switches[1].value, isFalse); // offers
      expect(switches[2].value, isFalse); // shippingUpdates
      expect(switches[3].value, isTrue); // marketing
    });
  });
}
