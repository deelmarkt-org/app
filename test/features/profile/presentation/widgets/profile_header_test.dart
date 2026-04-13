import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/profile_header.dart';
import 'package:deelmarkt/widgets/badges/deel_avatar.dart';

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

/// Pumps [ProfileHeader] inside ProviderScope + EasyLocalization.
///
/// ProfileHeader is a ConsumerWidget that reads profileNotifierProvider,
/// so ProviderScope is required. useMockDataProvider is forced to true so
/// mock repositories are used (no real Supabase calls in tests).
///
/// The mock load() has a 200ms user delay + 500ms listings/reviews delay,
/// so we drain timers before settling.
Future<void> _pumpHeader(
  WidgetTester tester,
  UserEntity user, {
  List<Override> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting('en');
  await initializeDateFormatting('nl');

  await tester.pumpWidget(
    ProviderScope(
      overrides: [useMockDataProvider.overrideWithValue(true), ...overrides],
      child: EasyLocalization(
        supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
        fallbackLocale: const Locale('en', 'US'),
        path: 'assets/l10n',
        child: MaterialApp(
          theme: DeelmarktTheme.light,
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(disableAnimations: true),
                    child: SingleChildScrollView(
                      child: ProfileHeader(user: user),
                    ),
                  ),
            ),
          ),
        ),
      ),
    ),
  );
  // Drain mock repo timers: 200ms user + 600ms listings/reviews.
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------

final _testUser = UserEntity(
  id: 'user-001',
  displayName: 'Jan de Vries',
  kycLevel: KycLevel.level1,
  location: 'Amsterdam',
  badges: const [BadgeType.emailVerified],
  averageRating: 4.7,
  reviewCount: 23,
  responseTimeMinutes: 15,
  createdAt: DateTime(2025, 6),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('en');
    await initializeDateFormatting('nl');
  });

  group('ProfileHeader', () {
    testWidgets('renders DeelAvatar with correct display name', (tester) async {
      await _pumpHeader(tester, _testUser);

      final avatar = tester.widget<DeelAvatar>(find.byType(DeelAvatar));
      expect(avatar.displayName, 'Jan de Vries');
    });

    testWidgets('renders DeelAvatar with large size', (tester) async {
      await _pumpHeader(tester, _testUser);

      final avatar = tester.widget<DeelAvatar>(find.byType(DeelAvatar));
      expect(avatar.size, DeelAvatarSize.large);
    });

    testWidgets('shows display name as text', (tester) async {
      await _pumpHeader(tester, _testUser);

      expect(find.text('Jan de Vries'), findsOneWidget);
    });

    testWidgets('shows member since date', (tester) async {
      await _pumpHeader(tester, _testUser);

      // DateFormat.yMMM('en') produces e.g. "Jun 2025"
      expect(find.textContaining('Jun 2025'), findsOneWidget);
    });

    testWidgets('shows edit overlay on avatar', (tester) async {
      await _pumpHeader(tester, _testUser);

      final avatar = tester.widget<DeelAvatar>(find.byType(DeelAvatar));
      expect(avatar.showEditOverlay, isTrue);
    });

    testWidgets('renders with user that has avatar URL', (tester) async {
      final userWithAvatar = _testUser.copyWith(
        avatarUrl: 'https://example.com/avatar.jpg',
      );

      await _pumpHeader(tester, userWithAvatar);

      final avatar = tester.widget<DeelAvatar>(find.byType(DeelAvatar));
      expect(avatar.imageUrl, 'https://example.com/avatar.jpg');
    });

    testWidgets('tapping avatar opens bottom sheet with image picker options', (
      tester,
    ) async {
      await _pumpHeader(tester, _testUser);

      await tester.tap(find.byType(DeelAvatar));
      await tester.pumpAndSettle();

      expect(find.text('profile.pickPhoto'), findsOneWidget);
      expect(find.text('profile.takePhoto'), findsOneWidget);
      expect(find.text('profile.chooseFromGallery'), findsOneWidget);
    });

    testWidgets('tapping camera option in bottom sheet closes it', (
      tester,
    ) async {
      await _pumpHeader(tester, _testUser);

      await tester.tap(find.byType(DeelAvatar));
      await tester.pumpAndSettle();

      await tester.tap(find.text('profile.takePhoto'));
      await tester.pumpAndSettle();

      expect(find.text('profile.pickPhoto'), findsNothing);
    });

    testWidgets('tapping gallery option in bottom sheet closes it', (
      tester,
    ) async {
      await _pumpHeader(tester, _testUser);

      await tester.tap(find.byType(DeelAvatar));
      await tester.pumpAndSettle();

      await tester.tap(find.text('profile.chooseFromGallery'));
      await tester.pumpAndSettle();

      expect(find.text('profile.pickPhoto'), findsNothing);
    });

    testWidgets('bottom sheet has two ListTile options', (tester) async {
      await _pumpHeader(tester, _testUser);

      await tester.tap(find.byType(DeelAvatar));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNWidgets(2));
    });

    testWidgets('formats member since for single-digit month', (tester) async {
      final januaryUser = _testUser.copyWith(createdAt: DateTime(2024));
      await _pumpHeader(tester, januaryUser);

      // DateFormat.yMMM('en') for January 2024 → "Jan 2024"
      expect(find.textContaining('Jan 2024'), findsOneWidget);
    });

    testWidgets('formats member since for double-digit month', (tester) async {
      final decUser = _testUser.copyWith(createdAt: DateTime(2025, 12));
      await _pumpHeader(tester, decUser);

      // DateFormat.yMMM('en') for December 2025 → "Dec 2025"
      expect(find.textContaining('Dec 2025'), findsOneWidget);
    });

    testWidgets('renders without avatar URL (initials fallback)', (
      tester,
    ) async {
      final noAvatarUser = UserEntity(
        id: 'user-002',
        displayName: 'Pieter Bakker',
        kycLevel: KycLevel.level0,
        createdAt: DateTime(2026, 3),
      );

      await _pumpHeader(tester, noAvatarUser);

      final avatar = tester.widget<DeelAvatar>(find.byType(DeelAvatar));
      expect(avatar.imageUrl, isNull);
      expect(avatar.displayName, 'Pieter Bakker');
      expect(find.text('Pieter Bakker'), findsOneWidget);
    });

    testWidgets('member since text includes the key path', (tester) async {
      await _pumpHeader(tester, _testUser);

      expect(find.textContaining('profile.memberSince'), findsOneWidget);
    });

    testWidgets('renders onEditTap callback on avatar', (tester) async {
      await _pumpHeader(tester, _testUser);

      final avatar = tester.widget<DeelAvatar>(find.byType(DeelAvatar));
      expect(avatar.onEditTap, isNotNull);
    });
  });
}
