import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/messages/presentation/widgets/make_offer_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Widget buildTest() {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: MaterialApp(
        theme: DeelmarktTheme.light,
        home: Scaffold(
          body: Builder(
            builder:
                (ctx) => ElevatedButton(
                  onPressed: () => MakeOfferSheet.show(ctx),
                  child: const Text('open'),
                ),
          ),
        ),
      ),
    );
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(buildTest());
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('MakeOfferSheet', () {
    testWidgets('renders amount field and send button', (tester) async {
      await openSheet(tester);

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('returns cents when valid amount entered', (tester) async {
      int? result;
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
          fallbackLocale: const Locale('en', 'US'),
          path: 'assets/l10n',
          child: MaterialApp(
            theme: DeelmarktTheme.light,
            home: Scaffold(
              body: Builder(
                builder:
                    (ctx) => ElevatedButton(
                      onPressed: () async {
                        result = await MakeOfferSheet.show(ctx);
                      },
                      child: const Text('open'),
                    ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '99,50');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(result, 9950);
    });

    testWidgets('shows error for zero amount', (tester) async {
      await openSheet(tester);

      await tester.enterText(find.byType(TextFormField), '0');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('shows error for empty input', (tester) async {
      await openSheet(tester);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('cancel button dismisses sheet without result', (tester) async {
      int? result;
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
          fallbackLocale: const Locale('en', 'US'),
          path: 'assets/l10n',
          child: MaterialApp(
            theme: DeelmarktTheme.light,
            home: Scaffold(
              body: Builder(
                builder:
                    (ctx) => ElevatedButton(
                      onPressed: () async {
                        result = await MakeOfferSheet.show(ctx);
                      },
                      child: const Text('open'),
                    ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}
