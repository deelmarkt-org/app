import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/domain/entities/scam_reason.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/widgets/trust/scam_alert.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '_chat_thread_test_helpers.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('ChatThreadScreen scam alert wiring (P-37)', () {
    testWidgets('does not show ScamAlert when no messages are flagged', (
      tester,
    ) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeMessageRepository(
        conversations: [conv('c1')],
        messages: [msg('m1', DateTime(2026, 3, 25, 10), text: 'Safe message')],
      );
      await tester.pumpWidget(buildApp(repo: repo));
      await tester.pumpAndSettle();

      expect(find.byType(ScamAlert), findsNothing);
    });

    testWidgets('shows ScamAlert for high-confidence flagged message', (
      tester,
    ) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeMessageRepository(
        conversations: [conv('c1')],
        messages: [
          msg('m1', DateTime(2026, 3, 25, 10), text: 'Safe'),
          MessageEntity(
            id: 'm2',
            conversationId: 'c1',
            senderId: 'other-c1',
            text: 'Send money to my PayPal',
            createdAt: DateTime(2026, 3, 25, 11),
            scamConfidence: ScamConfidence.high,
            scamReasons: const [ScamReason.externalPaymentLink],
            scamFlaggedAt: DateTime(2026, 3, 25, 11),
          ),
        ],
      );
      await tester.pumpWidget(buildApp(repo: repo));
      await tester.pumpAndSettle();

      expect(find.byType(ScamAlert), findsOneWidget);
    });

    testWidgets('shows ScamAlert for low-confidence flagged message', (
      tester,
    ) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeMessageRepository(
        conversations: [conv('c1')],
        messages: [
          MessageEntity(
            id: 'm1',
            conversationId: 'c1',
            senderId: 'other-c1',
            text: 'Suspicious message',
            createdAt: DateTime(2026, 3, 25, 10),
            scamConfidence: ScamConfidence.low,
            scamReasons: const [ScamReason.urgencyPressure],
            scamFlaggedAt: DateTime(2026, 3, 25, 10),
          ),
        ],
      );
      await tester.pumpWidget(buildApp(repo: repo));
      await tester.pumpAndSettle();

      expect(find.byType(ScamAlert), findsOneWidget);
    });

    testWidgets('picks high over low when both exist', (tester) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeMessageRepository(
        conversations: [conv('c1')],
        messages: [
          MessageEntity(
            id: 'm1',
            conversationId: 'c1',
            senderId: 'other-c1',
            text: 'Low confidence',
            createdAt: DateTime(2026, 3, 25, 10),
            scamConfidence: ScamConfidence.low,
            scamReasons: const [ScamReason.urgencyPressure],
            scamFlaggedAt: DateTime(2026, 3, 25, 10),
          ),
          MessageEntity(
            id: 'm2',
            conversationId: 'c1',
            senderId: 'other-c1',
            text: 'High confidence',
            createdAt: DateTime(2026, 3, 25, 11),
            scamConfidence: ScamConfidence.high,
            scamReasons: const [ScamReason.externalPaymentLink],
            scamFlaggedAt: DateTime(2026, 3, 25, 11),
          ),
        ],
      );
      await tester.pumpWidget(buildApp(repo: repo));
      await tester.pumpAndSettle();

      expect(find.byType(ScamAlert), findsOneWidget);

      // High-confidence alerts have a11y label for high
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label != null &&
              w.properties.label!.contains('a11y_high'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('ScamAlert renders in dark theme with flagged message', (
      tester,
    ) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeMessageRepository(
        conversations: [conv('c1')],
        messages: [
          MessageEntity(
            id: 'm1',
            conversationId: 'c1',
            senderId: 'other-c1',
            text: 'Scam',
            createdAt: DateTime(2026, 3, 25, 10),
            scamConfidence: ScamConfidence.high,
            scamReasons: const [ScamReason.offSiteContact],
            scamFlaggedAt: DateTime(2026, 3, 25, 10),
          ),
        ],
      );
      await tester.pumpWidget(buildApp(repo: repo, theme: DeelmarktTheme.dark));
      await tester.pumpAndSettle();

      expect(find.byType(ScamAlert), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping Report on high-confidence alert shows snackbar', (
      tester,
    ) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeMessageRepository(
        conversations: [conv('c1')],
        messages: [
          MessageEntity(
            id: 'm1',
            conversationId: 'c1',
            senderId: 'other-c1',
            text: 'Pay me externally',
            createdAt: DateTime(2026, 3, 25, 10),
            scamConfidence: ScamConfidence.high,
            scamReasons: const [ScamReason.externalPaymentLink],
            scamFlaggedAt: DateTime(2026, 3, 25, 10),
          ),
        ],
      );
      await tester.pumpWidget(buildApp(repo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('scam_alert.report'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('tapping Dismiss on low-confidence alert hides the banner', (
      tester,
    ) async {
      setLargeScreen(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeMessageRepository(
        conversations: [conv('c1')],
        messages: [
          MessageEntity(
            id: 'm1',
            conversationId: 'c1',
            senderId: 'other-c1',
            text: 'Suspicious',
            createdAt: DateTime(2026, 3, 25, 10),
            scamConfidence: ScamConfidence.low,
            scamReasons: const [ScamReason.urgencyPressure],
            scamFlaggedAt: DateTime(2026, 3, 25, 10),
          ),
        ],
      );
      await tester.pumpWidget(buildApp(repo: repo));
      await tester.pumpAndSettle();

      expect(find.byType(ScamAlert), findsOneWidget);

      final dismissFinder = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label != null &&
            w.properties.label!.contains('scam_alert.dismiss'),
      );
      expect(dismissFinder, findsOneWidget);
      await tester.tap(dismissFinder);
      await tester.pump();

      // After dismiss, the banner should be hidden
      expect(find.byType(ScamAlert), findsNothing);
    });
  });
}
