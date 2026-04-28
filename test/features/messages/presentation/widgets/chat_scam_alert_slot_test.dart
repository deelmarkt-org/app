import 'package:deelmarkt/core/domain/entities/scam_reason.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/presentation/chat_thread_state.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_scam_alert_slot.dart';
import 'package:deelmarkt/widgets/trust/scam_alert.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ConversationEntity _conv() => ConversationEntity(
  id: 'c1',
  listingId: 'l1',
  listingTitle: 'Canyon Speedmax',
  listingImageUrl: null,
  otherUserId: 'other-001',
  otherUserName: 'Jan',
  lastMessageText: 'hi',
  lastMessageAt: DateTime(2026, 3, 25, 14),
);

MessageEntity _msg({
  required ScamConfidence confidence,
  List<ScamReason>? reasons,
}) => MessageEntity(
  id: 'm1',
  conversationId: 'c1',
  senderId: 'other-001',
  text: 'Suspicious text',
  createdAt: DateTime(2026, 3, 25, 10),
  scamConfidence: confidence,
  scamReasons: reasons,
  scamFlaggedAt:
      confidence != ScamConfidence.none ? DateTime(2026, 3, 25, 10) : null,
);

Widget _buildTest(ChatThreadState state) {
  return ProviderScope(
    child: EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: MaterialApp(home: Scaffold(body: ChatScamAlertSlot(state: state))),
    ),
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('ChatScamAlertSlot', () {
    testWidgets('shows nothing when messages list is empty', (tester) async {
      final state = ChatThreadState(conversation: _conv(), messages: const []);
      await tester.pumpWidget(_buildTest(state));
      await tester.pumpAndSettle();

      expect(find.byType(ScamAlert), findsNothing);
    });

    testWidgets('shows nothing when latest message has ScamConfidence.none', (
      tester,
    ) async {
      final state = ChatThreadState(
        conversation: _conv(),
        messages: [_msg(confidence: ScamConfidence.none)],
      );
      await tester.pumpWidget(_buildTest(state));
      await tester.pumpAndSettle();

      expect(find.byType(ScamAlert), findsNothing);
    });

    testWidgets('shows ScamAlert for low-confidence message', (tester) async {
      final state = ChatThreadState(
        conversation: _conv(),
        messages: [
          _msg(
            confidence: ScamConfidence.low,
            reasons: const [ScamReason.urgencyPressure],
          ),
        ],
      );
      await tester.pumpWidget(_buildTest(state));
      await tester.pumpAndSettle();

      expect(find.byType(ScamAlert), findsOneWidget);
    });

    testWidgets('shows ScamAlert for high-confidence message', (tester) async {
      final state = ChatThreadState(
        conversation: _conv(),
        messages: [
          _msg(
            confidence: ScamConfidence.high,
            reasons: const [ScamReason.externalPaymentLink],
          ),
        ],
      );
      await tester.pumpWidget(_buildTest(state));
      await tester.pumpAndSettle();

      expect(find.byType(ScamAlert), findsOneWidget);
    });

    testWidgets('dismissing low-confidence alert hides the banner', (
      tester,
    ) async {
      final state = ChatThreadState(
        conversation: _conv(),
        messages: [
          _msg(
            confidence: ScamConfidence.low,
            reasons: const [ScamReason.urgencyPressure],
          ),
        ],
      );
      await tester.pumpWidget(_buildTest(state));
      await tester.pumpAndSettle();

      expect(find.byType(ScamAlert), findsOneWidget);

      final dismissNode = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .firstWhere(
            (s) =>
                s.properties.label != null &&
                s.properties.label!.contains('scam_alert.dismiss'),
            orElse: () => throw TestFailure('Dismiss Semantics node not found'),
          );
      await tester.tap(find.byWidget(dismissNode));
      await tester.pump();

      expect(find.byType(ScamAlert), findsNothing);
    });
  });
}
