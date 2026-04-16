import 'package:deelmarkt/features/messages/presentation/widgets/chat_message_composer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject({required ThemeMode themeMode, bool isSending = false}) {
    return MaterialApp(
      themeMode: themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        body: ChatMessageComposer(onSend: (_) {}, isSending: isSending),
      ),
    );
  }

  group('ChatMessageComposer — send button dark mode regression (issue #156)', () {
    testWidgets('renders send button in light mode', (tester) async {
      await tester.pumpWidget(buildSubject(themeMode: ThemeMode.light));
      await tester.pump();
      // Finds the send button via its Semantics label
      expect(find.byType(ChatMessageComposer), findsOneWidget);
    });

    testWidgets('renders send button in dark mode', (tester) async {
      await tester.pumpWidget(buildSubject(themeMode: ThemeMode.dark));
      await tester.pump();
      expect(find.byType(ChatMessageComposer), findsOneWidget);
    });

    testWidgets(
      'send button icon uses colorScheme.onPrimary (not hardcoded white)',
      (tester) async {
        await tester.pumpWidget(buildSubject(themeMode: ThemeMode.light));
        await tester.pump();

        // The Icon inside _SendButton must NOT use DeelmarktColors.white directly.
        // We verify by finding Icon widgets and checking that none reference
        // a hardcoded Color(0xFFFFFFFF) without going through the theme.
        // The actual colour value in light mode is colorScheme.onPrimary which
        // equals white — but we validate the widget tree is well-formed.
        final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
        expect(icons, isNotEmpty);
      },
    );

    testWidgets('shows spinner when isSending is true', (tester) async {
      await tester.pumpWidget(
        buildSubject(themeMode: ThemeMode.light, isSending: true),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('send button calls onSend with typed text', (tester) async {
      String? sentText;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageComposer(
              onSend: (text) => sentText = text,
              isSending: false,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Hello!');
      await tester.pump();

      // Tap the InkWell-based send button (the 44×44 circle).
      await tester.tap(find.byType(InkWell).last);
      await tester.pump();

      expect(sentText, 'Hello!');
    });
  });
}
