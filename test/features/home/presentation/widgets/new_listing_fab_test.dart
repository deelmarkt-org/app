import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/home/presentation/widgets/new_listing_fab.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Widget buildSubject({ThemeData? theme}) {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: MaterialApp(
        theme: theme ?? DeelmarktTheme.light,
        home: const Scaffold(floatingActionButton: NewListingFab()),
        onGenerateRoute:
            (_) => MaterialPageRoute<void>(builder: (_) => const Scaffold()),
      ),
    );
  }

  group('NewListingFab', () {
    testWidgets('renders FloatingActionButton.extended', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('has Semantics with button=true', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      final semanticsWidgets = tester.widgetList<Semantics>(
        find.byType(Semantics),
      );
      final hasButtonSemantics = semanticsWidgets.any(
        (s) => s.properties.button == true,
      );
      expect(hasButtonSemantics, isTrue);

      await tester.pumpAndSettle();
    });

    testWidgets('has primary (orange) background color', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.backgroundColor, equals(DeelmarktColors.primary));
    });

    testWidgets('shows an Icon widget for the plus icon', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('FAB has an onPressed callback (is tappable)', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.onPressed, isNotNull);
    });

    testWidgets('renders in dark mode without error', (tester) async {
      await tester.pumpWidget(buildSubject(theme: DeelmarktTheme.dark));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
