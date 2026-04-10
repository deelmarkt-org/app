import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/home/presentation/widgets/seller_home_empty_view.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildSubject({String? userName, ThemeData? theme}) {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: ProviderScope(
        overrides: [
          useMockDataProvider.overrideWithValue(true),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          theme: theme ?? DeelmarktTheme.light,
          home: Scaffold(body: SellerHomeEmptyView(userName: userName)),
          onGenerateRoute:
              (_) => MaterialPageRoute<void>(builder: (_) => const Scaffold()),
        ),
      ),
    );
  }

  group('SellerHomeEmptyView', () {
    testWidgets('renders CustomScrollView', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(CustomScrollView), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('renders DeelButton', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(DeelButton), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('renders with userName without error', (tester) async {
      // tr() returns the key in tests (l10n assets not loaded).
      // Verify the view builds successfully when a userName is passed.
      await tester.pumpWidget(buildSubject(userName: 'Alice'));
      await tester.pump();

      expect(find.byType(SellerHomeEmptyView), findsOneWidget);
    });

    testWidgets('renders without error when userName is null', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(SellerHomeEmptyView), findsOneWidget);
    });

    testWidgets('renders in dark mode without error', (tester) async {
      await tester.pumpWidget(buildSubject(theme: DeelmarktTheme.dark));
      await tester.pumpAndSettle();

      expect(find.byType(CustomScrollView), findsOneWidget);
    });
  });
}
