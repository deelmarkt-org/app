import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/message_bubble.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  final message = MessageEntity(
    id: 'msg-1',
    conversationId: 'conv-1',
    senderId: 'user-1',
    text: 'Hoi, is dit nog beschikbaar?',
    createdAt: DateTime(2026, 1, 15, 10, 30),
  );

  Widget buildTest({required bool isSelf}) {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: MaterialApp(
        theme: DeelmarktTheme.light,
        home: Scaffold(body: MessageBubble(message: message, isSelf: isSelf)),
      ),
    );
  }

  testWidgets('renders message text', (tester) async {
    await tester.pumpWidget(buildTest(isSelf: false));
    await tester.pump();

    expect(find.text('Hoi, is dit nog beschikbaar?'), findsOneWidget);
  });

  testWidgets('renders self bubble without throwing', (tester) async {
    await tester.pumpWidget(buildTest(isSelf: true));
    await tester.pump();

    expect(find.byType(MessageBubble), findsOneWidget);
  });

  testWidgets('renders other bubble without throwing', (tester) async {
    await tester.pumpWidget(buildTest(isSelf: false));
    await tester.pump();

    expect(find.byType(MessageBubble), findsOneWidget);
  });
}
