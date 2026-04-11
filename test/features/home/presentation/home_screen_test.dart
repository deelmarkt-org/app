import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/home/domain/entities/home_mode.dart';
import 'package:deelmarkt/features/home/presentation/home_mode_notifier.dart';
import 'package:deelmarkt/features/home/presentation/home_notifier.dart';
import 'package:deelmarkt/features/home/presentation/home_screen.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_listing_card.dart';

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

  /// Builds HomeScreen with a stub [HomeNotifier] that never resolves
  /// (stays in loading state), so no timers from mock repositories fire.
  Widget buildSubject({List<Override> extraOverrides = const []}) {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: ProviderScope(
        overrides: [
          useMockDataProvider.overrideWithValue(true),
          sharedPreferencesProvider.overrideWithValue(prefs),
          // Always override homeNotifier to avoid pending timers from
          // MockCategoryRepository which uses a 200ms artificial delay.
          homeNotifierProvider.overrideWith(
            () => _NeverResolvingHomeNotifier(),
          ),
          ...extraOverrides,
        ],
        child: MaterialApp(
          theme: DeelmarktTheme.light,
          home: const Scaffold(body: HomeScreen()),
          onGenerateRoute:
              (_) => MaterialPageRoute<void>(builder: (_) => const Scaffold()),
        ),
      ),
    );
  }

  group('HomeScreen', () {
    testWidgets('renders AnimatedSwitcher', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          extraOverrides: [currentUserProvider.overrideWithValue(null)],
        ),
      );
      await tester.pump();

      expect(find.byType(AnimatedSwitcher), findsOneWidget);
    });

    testWidgets('shows buyer loading skeleton when unauthenticated', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          extraOverrides: [currentUserProvider.overrideWithValue(null)],
        ),
      );
      await tester.pump();

      expect(find.byType(SkeletonListingCard), findsWidgets);
    });

    testWidgets('unauthenticated user shows buyer mode even with seller mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          extraOverrides: [
            currentUserProvider.overrideWithValue(null),
            homeModeNotifierProvider.overrideWith(
              () => _StubHomeModeNotifier(HomeMode.seller),
            ),
          ],
        ),
      );
      await tester.pump();

      // Auth guard forces buyer mode — skeleton listing cards visible.
      expect(find.byType(SkeletonListingCard), findsWidgets);
    });

    testWidgets('buyer mode renders CustomScrollView', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          extraOverrides: [
            currentUserProvider.overrideWithValue(null),
            homeModeNotifierProvider.overrideWith(
              () => _StubHomeModeNotifier(HomeMode.buyer),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(CustomScrollView), findsWidgets);
    });

    testWidgets('widget tree is under a Scaffold', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          extraOverrides: [currentUserProvider.overrideWithValue(null)],
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}

// ---------------------------------------------------------------------------
// Stub notifiers
// ---------------------------------------------------------------------------

/// HomeNotifier that never resolves — stays in loading state forever.
/// Used to prevent pending timers from MockCategoryRepository.
class _NeverResolvingHomeNotifier extends HomeNotifier {
  @override
  Future<HomeState> build() => Completer<HomeState>().future;

  @override
  Future<void> refresh() async {}

  @override
  Future<void> toggleFavourite(String listingId) async {}
}

class _StubHomeModeNotifier extends HomeModeNotifier {
  _StubHomeModeNotifier(this._mode);
  final HomeMode _mode;

  @override
  HomeMode build() => _mode;
}
