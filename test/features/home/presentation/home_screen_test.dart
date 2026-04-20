import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/core/services/unleash_service.dart';
import 'package:deelmarkt/features/home/domain/entities/home_mode.dart';
import 'package:deelmarkt/features/home/presentation/home_mode_notifier.dart';
import 'package:deelmarkt/features/home/presentation/home_notifier.dart';
import 'package:deelmarkt/features/home/presentation/home_screen.dart';
import 'package:deelmarkt/features/home/presentation/seller_home_notifier.dart';
import 'package:deelmarkt/features/home/domain/entities/seller_stats_entity.dart';
import 'package:deelmarkt/features/home/presentation/widgets/home_data_view.dart';
import 'package:deelmarkt/features/home/presentation/widgets/seller_home_empty_view.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';
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
          // GH-59: EscrowAwareListingCard reads this flag via Unleash.
          isFeatureEnabledProvider(
            FeatureFlags.listingsEscrowBadge,
          ).overrideWith((ref) => false),
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

    // ── Phase 3.3 additions ────────────────────────────────────────────────

    testWidgets('buyer mode error state shows ErrorState widget', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          extraOverrides: [
            currentUserProvider.overrideWithValue(null),
            homeModeNotifierProvider.overrideWith(
              () => _StubHomeModeNotifier(HomeMode.buyer),
            ),
            homeNotifierProvider.overrideWith(() => _ErrorHomeNotifier()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('buyer mode error state retry triggers refresh', (
      tester,
    ) async {
      final notifier = _TrackingErrorHomeNotifier();
      await tester.pumpWidget(
        buildSubject(
          extraOverrides: [
            currentUserProvider.overrideWithValue(null),
            homeModeNotifierProvider.overrideWith(
              () => _StubHomeModeNotifier(HomeMode.buyer),
            ),
            homeNotifierProvider.overrideWith(() => notifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle();

      expect(notifier.refreshCallCount, 1);
    });

    testWidgets('buyer mode data state shows HomeDataView', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          extraOverrides: [
            currentUserProvider.overrideWithValue(null),
            homeModeNotifierProvider.overrideWith(
              () => _StubHomeModeNotifier(HomeMode.buyer),
            ),
            homeNotifierProvider.overrideWith(
              () => _DataHomeNotifier(const HomeState()),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeDataView), findsOneWidget);
    });

    testWidgets('seller mode empty data shows SellerHomeEmptyView', (
      tester,
    ) async {
      const emptyState = SellerHomeState(
        stats: SellerStatsEntity(
          totalSalesCents: 0,
          activeListingsCount: 0,
          unreadMessagesCount: 0,
        ),
        actions: [],
        listings: [],
      );
      await tester.pumpWidget(
        buildSubject(
          extraOverrides: [
            // Authenticated user required so the auth guard does not force buyer mode.
            currentUserProvider.overrideWith((_) => _stubUser),
            homeModeNotifierProvider.overrideWith(
              () => _StubHomeModeNotifier(HomeMode.seller),
            ),
            sellerHomeNotifierProvider.overrideWith(
              () => _StubSellerHomeNotifier(emptyState),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SellerHomeEmptyView), findsOneWidget);
    });
  });
}

// ---------------------------------------------------------------------------
// Stub helpers
// ---------------------------------------------------------------------------

const _stubUser = User(
  id: 'user-stub',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

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

/// Always throws — triggers the error branch in buyer mode.
class _ErrorHomeNotifier extends HomeNotifier {
  @override
  Future<HomeState> build() async => throw Exception('network error');

  @override
  Future<void> refresh() async {
    state = AsyncValue.error(Exception('network error'), StackTrace.empty);
  }

  @override
  Future<void> toggleFavourite(String listingId) async {}
}

/// Throws on build but tracks refresh calls — for retry assertion.
class _TrackingErrorHomeNotifier extends HomeNotifier {
  int refreshCallCount = 0;

  @override
  Future<HomeState> build() async => throw Exception('network error');

  @override
  Future<void> refresh() async {
    refreshCallCount++;
    state = AsyncValue.error(Exception('network error'), StackTrace.empty);
  }

  @override
  Future<void> toggleFavourite(String listingId) async {}
}

/// Returns fixed HomeState — triggers the data branch.
class _DataHomeNotifier extends HomeNotifier {
  _DataHomeNotifier(this._data);
  final HomeState _data;

  @override
  Future<HomeState> build() async => _data;

  @override
  Future<void> refresh() async {}

  @override
  Future<void> toggleFavourite(String listingId) async {}
}

/// Stub for seller home — returns fixed state.
class _StubSellerHomeNotifier extends SellerHomeNotifier {
  _StubSellerHomeNotifier(this._state);
  final SellerHomeState _state;

  @override
  Future<SellerHomeState> build() async => _state;

  @override
  Future<void> refresh() async => state = AsyncValue.data(_state);
}
