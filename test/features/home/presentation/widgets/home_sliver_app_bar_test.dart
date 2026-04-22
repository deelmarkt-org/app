import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/home/presentation/widgets/home_mode_pill_switch.dart';
import 'package:deelmarkt/features/home/presentation/widgets/home_sliver_app_bar.dart';

User _testUser() => const User(
  id: 'test-user-1',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00.000Z',
);

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

  Widget buildSubject({List<Widget> extraActions = const []}) {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: ProviderScope(
        overrides: [
          useMockDataProvider.overrideWithValue(true),
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUserProvider.overrideWithValue(_testUser()),
        ],
        child: MaterialApp(
          theme: DeelmarktTheme.light,
          home: Scaffold(
            body: CustomScrollView(
              slivers: [HomeSliverAppBar(extraActions: extraActions)],
            ),
          ),
        ),
      ),
    );
  }

  group('HomeSliverAppBar', () {
    testWidgets('renders the app name in bold primary-coloured text', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // In tests, EasyLocalization renders the raw key (translations are
      // async). We assert structural + style properties instead of the
      // translated string so the test survives l10n changes.
      final titleWidget = tester.widget<SliverAppBar>(
        find.byType(SliverAppBar),
      );
      final title = titleWidget.title as Text;
      expect(title.style?.fontWeight, FontWeight.w700);
      expect(title.style?.color, DeelmarktTheme.light.colorScheme.primary);
    });

    testWidgets('includes the HomeModePillSwitch in the actions slot', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(HomeModePillSwitch), findsOneWidget);
    });

    testWidgets('uses floating behaviour so the bar re-appears on scroll', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      final appBar = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
      expect(appBar.floating, isTrue);
    });

    testWidgets('renders no extra actions by default', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // Only the mode pill switch — no extra IconButton children.
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('renders supplied extraActions after the pill switch', (
      tester,
    ) async {
      const extras = [
        IconButton(
          key: Key('extra-1'),
          icon: Icon(Icons.favorite),
          onPressed: null,
        ),
        IconButton(
          key: Key('extra-2'),
          icon: Icon(Icons.search),
          onPressed: null,
        ),
      ];

      await tester.pumpWidget(buildSubject(extraActions: extras));
      await tester.pump();

      expect(find.byKey(const Key('extra-1')), findsOneWidget);
      expect(find.byKey(const Key('extra-2')), findsOneWidget);
    });
  });
}
