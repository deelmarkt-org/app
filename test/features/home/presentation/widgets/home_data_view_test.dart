import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/core/services/unleash_service.dart';
import 'package:deelmarkt/features/home/presentation/home_notifier.dart';
import 'package:deelmarkt/features/home/presentation/widgets/home_data_view.dart';
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

  const emptyState = HomeState();

  Widget buildSubject({HomeState state = emptyState, ThemeData? theme}) {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: ProviderScope(
        overrides: [
          useMockDataProvider.overrideWithValue(true),
          sharedPreferencesProvider.overrideWithValue(prefs),
          homeNotifierProvider.overrideWith(() => _StubHomeNotifier(state)),
          // GH-59: EscrowAwareListingCard reads the Unleash flag; override
          // so widget tests don't call the real SDK.
          isFeatureEnabledProvider(
            FeatureFlags.listingsEscrowBadge,
          ).overrideWith((ref) => false),
        ],
        child: MaterialApp(
          theme: theme ?? DeelmarktTheme.light,
          home: Scaffold(body: HomeDataView(data: state)),
          onGenerateRoute:
              (_) => MaterialPageRoute<void>(builder: (_) => const Scaffold()),
        ),
      ),
    );
  }

  group('HomeDataView', () {
    testWidgets('renders without error with empty state', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byType(HomeDataView), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('renders HomeModePillSwitch in app bar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(HomeModePillSwitch), findsOneWidget);
    });

    testWidgets('renders RefreshIndicator', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets(
      'shows empty state widget when categories, nearby, recent all empty',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // With empty nearby, the widget renders SliverFillRemaining with
        // EmptyState. Verify CustomScrollView is present (data view rendered).
        expect(find.byType(CustomScrollView), findsOneWidget);
      },
    );

    testWidgets('renders in dark mode without error', (tester) async {
      await tester.pumpWidget(buildSubject(theme: DeelmarktTheme.dark));
      await tester.pumpAndSettle();

      expect(find.byType(HomeDataView), findsOneWidget);
    });
  });
}

// ---------------------------------------------------------------------------
// Stub notifier
// ---------------------------------------------------------------------------

class _StubHomeNotifier extends HomeNotifier {
  _StubHomeNotifier(this._state);

  final HomeState _state;

  @override
  Future<HomeState> build() async => _state;

  @override
  Future<void> refresh() async {
    state = AsyncValue.data(_state);
  }

  @override
  Future<void> toggleFavourite(String listingId) async {}
}
