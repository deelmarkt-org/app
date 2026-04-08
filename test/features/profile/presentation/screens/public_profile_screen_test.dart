import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/public_profile_notifier.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/public_profile_state.dart';
import 'package:deelmarkt/features/profile/presentation/screens/public_profile_screen.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/public_profile_header.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/public_profile_skeleton.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/reviews_tab_view.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';

/// Pumps [PublicProfileScreen] wrapped in EasyLocalization + ProviderScope.
///
/// Installs a [FlutterError.onError] override to suppress RenderFlex overflow
/// errors caused by long `.tr()` key paths in the test environment (e.g.
/// "seller_profile.member_since" is wider than the real translated text).
Future<void> _pumpScreen(
  WidgetTester tester, {
  required String userId,
  required List<Override> overrides,
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting('en');
  await initializeDateFormatting('nl');

  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: EasyLocalization(
        supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
        fallbackLocale: const Locale('en', 'US'),
        path: 'assets/l10n',
        child: MaterialApp(
          theme: DeelmarktTheme.light,
          home: PublicProfileScreen(userId: userId),
        ),
      ),
    ),
  );

  // Suppress overflow errors caused by long .tr() key paths in test mode.
  // Capture the test framework's handler so non-overflow errors still fail.
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.toString().contains('overflowed')) return;
    originalOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = originalOnError);

  // Let mock repos (200ms delay) resolve, then settle animations.
  await tester.pump(const Duration(milliseconds: 1200));
  await tester.pumpAndSettle();
}

Future<List<Override>> _mockOverrides() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return [
    useMockDataProvider.overrideWithValue(true),
    sharedPreferencesProvider.overrideWithValue(prefs),
  ];
}

/// Stub notifier that returns a fixed [PublicProfileState] without I/O.
class _StubNotifier extends PublicProfileNotifier {
  _StubNotifier(this._fixedState);

  final PublicProfileState _fixedState;

  @override
  PublicProfileState build(String userId) => _fixedState;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PublicProfileScreen', () {
    testWidgets('renders AppBar title and header after data loads', (
      tester,
    ) async {
      final overrides = await _mockOverrides();
      await _pumpScreen(tester, userId: 'user-001', overrides: overrides);

      expect(find.text('seller_profile.title'), findsOneWidget);
      expect(find.byType(PublicProfileHeader), findsOneWidget);
    });

    testWidgets('renders tab bar with listings and reviews tabs', (
      tester,
    ) async {
      final overrides = await _mockOverrides();
      await _pumpScreen(tester, userId: 'user-001', overrides: overrides);

      expect(find.text('seller_profile.tab_listings'), findsOneWidget);
      expect(find.text('seller_profile.tab_reviews'), findsOneWidget);
    });

    testWidgets('renders popup menu with more-actions tooltip', (tester) async {
      final overrides = await _mockOverrides();
      await _pumpScreen(tester, userId: 'user-001', overrides: overrides);

      expect(find.byTooltip('seller_profile.more_actions'), findsOneWidget);
    });

    testWidgets('can switch to reviews tab', (tester) async {
      final overrides = await _mockOverrides();
      await _pumpScreen(tester, userId: 'user-001', overrides: overrides);

      await tester.tap(find.text('seller_profile.tab_reviews'));
      await tester.pumpAndSettle();

      expect(find.byType(ReviewsTabView), findsOneWidget);
    });

    testWidgets('shows skeleton while profile is loading', (tester) async {
      const loadingState = PublicProfileState();
      // Do not use _pumpScreen here: PublicProfileSkeleton uses Shimmer
      // (infinite animation) which causes pumpAndSettle to time out.
      // Instead, pump just enough frames to build the widget tree.
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final overrides = <Override>[
        publicProfileNotifierProvider(
          'user-001',
        ).overrideWith(() => _StubNotifier(loadingState)),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: EasyLocalization(
            supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
            fallbackLocale: const Locale('en', 'US'),
            path: 'assets/l10n',
            child: MaterialApp(
              theme: DeelmarktTheme.light,
              home: const PublicProfileScreen(userId: 'user-001'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(PublicProfileSkeleton), findsOneWidget);
      expect(find.byType(PublicProfileHeader), findsNothing);
    });

    testWidgets('shows error state when profile fetch fails', (tester) async {
      final errorState = PublicProfileState(
        user: AsyncValue.error(Exception('network error'), StackTrace.empty),
      );
      final overrides = <Override>[
        publicProfileNotifierProvider(
          'user-001',
        ).overrideWith(() => _StubNotifier(errorState)),
      ];
      await _pumpScreen(tester, userId: 'user-001', overrides: overrides);

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.byType(PublicProfileHeader), findsNothing);
    });

    testWidgets('shows not-found error state when user does not exist', (
      tester,
    ) async {
      const emptyState = PublicProfileState(user: AsyncValue.data(null));
      final overrides = <Override>[
        publicProfileNotifierProvider(
          'user-001',
        ).overrideWith(() => _StubNotifier(emptyState)),
      ];
      await _pumpScreen(tester, userId: 'user-001', overrides: overrides);

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.byType(PublicProfileHeader), findsNothing);
    });
  });
}
