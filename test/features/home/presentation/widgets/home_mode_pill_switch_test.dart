import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/home/domain/entities/home_mode.dart';
import 'package:deelmarkt/features/home/presentation/widgets/home_mode_pill_switch.dart';

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

  Widget buildSubject() {
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
          theme: DeelmarktTheme.light,
          home: const Scaffold(body: HomeModePillSwitch()),
        ),
      ),
    );
  }

  group('HomeModePillSwitch', () {
    testWidgets('renders SegmentedButton', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(SegmentedButton<HomeMode>), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('has Semantics wrapper', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(Semantics), findsWidgets);

      await tester.pumpAndSettle();
    });

    testWidgets('buyer segment shown initially', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final segmentedButton = tester.widget<SegmentedButton<HomeMode>>(
        find.byType(SegmentedButton<HomeMode>),
      );
      expect(segmentedButton.selected, contains(HomeMode.buyer));
    });

    testWidgets('seller segment shown when mode is seller', (tester) async {
      SharedPreferences.setMockInitialValues({'home_mode': 'seller'});
      final sellerPrefs = await SharedPreferences.getInstance();

      final widget = EasyLocalization(
        supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
        fallbackLocale: const Locale('en', 'US'),
        path: 'assets/l10n',
        child: ProviderScope(
          overrides: [
            useMockDataProvider.overrideWithValue(true),
            sharedPreferencesProvider.overrideWithValue(sellerPrefs),
          ],
          child: MaterialApp(
            theme: DeelmarktTheme.light,
            home: const Scaffold(body: HomeModePillSwitch()),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.byType(SegmentedButton<HomeMode>), findsOneWidget);
    });

    testWidgets('renders in dark mode without error', (tester) async {
      final widget = EasyLocalization(
        supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
        fallbackLocale: const Locale('en', 'US'),
        path: 'assets/l10n',
        child: ProviderScope(
          overrides: [
            useMockDataProvider.overrideWithValue(true),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            theme: DeelmarktTheme.dark,
            home: const Scaffold(body: HomeModePillSwitch()),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      expect(find.byType(SegmentedButton<HomeMode>), findsOneWidget);
    });

    testWidgets('has two segments for buyer and seller', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final segmentedButton = tester.widget<SegmentedButton<HomeMode>>(
        find.byType(SegmentedButton<HomeMode>),
      );
      expect(segmentedButton.segments.length, equals(2));
      expect(
        segmentedButton.segments.map((s) => s.value),
        containsAll([HomeMode.buyer, HomeMode.seller]),
      );
    });
  });
}
