import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/chat_message_composer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Widget wrap(Widget child) => EasyLocalization(
    supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
    fallbackLocale: const Locale('en', 'US'),
    path: 'assets/l10n',
    child: MaterialApp(
      theme: DeelmarktTheme.light,
      home: Scaffold(body: child),
    ),
  );

  group('ChatMessageComposer', () {
    testWidgets('send button is disabled on empty input', (tester) async {
      final sent = <String>[];
      await tester.pumpWidget(
        wrap(ChatMessageComposer(isSending: false, onSend: sent.add)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pump();
      expect(sent, isEmpty);
    });

    testWidgets('send button fires with trimmed text and clears input', (
      tester,
    ) async {
      final sent = <String>[];
      await tester.pumpWidget(
        wrap(ChatMessageComposer(isSending: false, onSend: sent.add)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '  Hallo wereld  ');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pumpAndSettle();

      expect(sent, ['  Hallo wereld  ']);
      expect(
        (tester.widget(find.byType(TextField)) as TextField).controller?.text,
        isEmpty,
      );
    });

    testWidgets('shows progress indicator when isSending is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(ChatMessageComposer(isSending: true, onSend: (_) {})),
      );
      // Don't pumpAndSettle — CircularProgressIndicator animates indefinitely.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
