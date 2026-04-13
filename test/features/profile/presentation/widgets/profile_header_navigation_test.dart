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
// Helpers
// ---------------------------------------------------------------------------

/// Pump [ProfileHeader] inside ProviderScope + EasyLocalization.
///
/// ProfileHeader is a ConsumerWidget and calls `context.locale`, so both
/// ProviderScope (Riverpod) and EasyLocalization must be present.
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
  // Pump enough to let the profileNotifierProvider auto-load complete.
  // MockUserRepository: 200ms + MockListingRepo/ReviewRepo: 500ms = 700ms total.
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

  group('ProfileHeader avatar picker wiring (#53)', () {
    testWidgets('edit overlay is enabled on avatar', (tester) async {
      await _pumpHeader(tester, _testUser);

      final avatar = tester.widget<DeelAvatar>(find.byType(DeelAvatar));
      expect(avatar.showEditOverlay, isTrue);
      expect(avatar.onEditTap, isNotNull);
    });

    testWidgets('tapping avatar opens image picker bottom sheet', (
      tester,
    ) async {
      await _pumpHeader(tester, _testUser);

      await tester.tap(find.byType(DeelAvatar));
      await tester.pumpAndSettle();

      expect(find.text('profile.pickPhoto'), findsOneWidget);
      expect(find.text('profile.takePhoto'), findsOneWidget);
      expect(find.text('profile.chooseFromGallery'), findsOneWidget);
    });

    testWidgets('no loading spinner when isUploadingAvatar is false', (
      tester,
    ) async {
      await _pumpHeader(tester, _testUser);

      // CircularProgressIndicator only shown during upload.
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('displays user displayName', (tester) async {
      await _pumpHeader(tester, _testUser);

      expect(find.text(_testUser.displayName), findsOneWidget);
    });

    testWidgets('DeelAvatar size is large', (tester) async {
      await _pumpHeader(tester, _testUser);

      final avatar = tester.widget<DeelAvatar>(find.byType(DeelAvatar));
      expect(avatar.size, DeelAvatarSize.large);
    });
  });
}
