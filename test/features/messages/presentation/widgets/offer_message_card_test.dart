import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_type.dart';
import 'package:deelmarkt/features/messages/domain/entities/offer_status.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/offer_message_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// These tests assert the Senior Staff Engineer decision from PLAN-chat-screens.md
/// §13 Q3: offer CTAs must render visually complete but only show a
/// "coming soon" SnackBar. They must NOT invoke any transaction or payment API.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  MessageEntity offer({
    String text = 'Bod: € 120,00',
    OfferStatus status = OfferStatus.pending,
  }) => MessageEntity(
    id: 'msg-1',
    conversationId: 'c1',
    senderId: 'u1',
    text: text,
    type: MessageType.offer,
    offerAmountCents: 12000,
    offerStatus: status,
    createdAt: DateTime(2026, 3, 25, 14),
  );

  Widget buildTest(Widget child) {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: MaterialApp(
        theme: DeelmarktTheme.light,
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  group('OfferMessageCard', () {
    testWidgets('renders three action buttons in pending state', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTest(OfferMessageCard(message: offer(), isSelf: false)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('tapping accept shows SnackBar, does not crash', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTest(OfferMessageCard(message: offer(), isSelf: false)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('tapping decline shows SnackBar', (tester) async {
      await tester.pumpWidget(
        buildTest(OfferMessageCard(message: offer(), isSelf: false)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('accepted state renders status row, no CTAs', (tester) async {
      await tester.pumpWidget(
        buildTest(
          OfferMessageCard(
            message: offer(status: OfferStatus.accepted),
            isSelf: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('declined state renders status row, no CTAs', (tester) async {
      await tester.pumpWidget(
        buildTest(
          OfferMessageCard(
            message: offer(status: OfferStatus.declined),
            isSelf: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsNothing);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });
  });
}
