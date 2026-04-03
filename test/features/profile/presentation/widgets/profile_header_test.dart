import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/profile_header.dart';
import 'package:deelmarkt/widgets/badges/deel_avatar.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('en');
    await initializeDateFormatting('nl');
  });

  final testUser = UserEntity(
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

  group('ProfileHeader', () {
    testWidgets('renders DeelAvatar with correct display name', (tester) async {
      await pumpLocalizedWidget(tester, ProfileHeader(user: testUser));

      final avatar = tester.widget<DeelAvatar>(find.byType(DeelAvatar));
      expect(avatar.displayName, 'Jan de Vries');
    });

    testWidgets('renders DeelAvatar with large size', (tester) async {
      await pumpLocalizedWidget(tester, ProfileHeader(user: testUser));

      final avatar = tester.widget<DeelAvatar>(find.byType(DeelAvatar));
      expect(avatar.size, DeelAvatarSize.large);
    });

    testWidgets('shows display name as text', (tester) async {
      await pumpLocalizedWidget(tester, ProfileHeader(user: testUser));

      expect(find.text('Jan de Vries'), findsOneWidget);
    });

    testWidgets('shows member since date', (tester) async {
      await pumpLocalizedWidget(tester, ProfileHeader(user: testUser));

      // DateFormat.yMMM('en') produces e.g. "Jun 2025"
      expect(find.textContaining('Jun 2025'), findsOneWidget);
    });

    testWidgets('shows edit overlay on avatar', (tester) async {
      await pumpLocalizedWidget(tester, ProfileHeader(user: testUser));

      final avatar = tester.widget<DeelAvatar>(find.byType(DeelAvatar));
      expect(avatar.showEditOverlay, isTrue);
    });

    testWidgets('renders with user that has avatar URL', (tester) async {
      final userWithAvatar = testUser.copyWith(
        avatarUrl: 'https://example.com/avatar.jpg',
      );

      await pumpLocalizedWidget(tester, ProfileHeader(user: userWithAvatar));

      final avatar = tester.widget<DeelAvatar>(find.byType(DeelAvatar));
      expect(avatar.imageUrl, 'https://example.com/avatar.jpg');
    });

    testWidgets('tapping avatar opens bottom sheet with image picker options', (
      tester,
    ) async {
      await pumpLocalizedWidget(tester, ProfileHeader(user: testUser));

      await tester.tap(find.byType(DeelAvatar));
      await tester.pumpAndSettle();

      expect(find.text('profile.pickPhoto'), findsOneWidget);
      expect(find.text('profile.takePhoto'), findsOneWidget);
      expect(find.text('profile.chooseFromGallery'), findsOneWidget);
    });

    testWidgets('tapping camera option in bottom sheet closes it', (
      tester,
    ) async {
      await pumpLocalizedWidget(tester, ProfileHeader(user: testUser));

      await tester.tap(find.byType(DeelAvatar));
      await tester.pumpAndSettle();

      await tester.tap(find.text('profile.takePhoto'));
      await tester.pumpAndSettle();

      expect(find.text('profile.pickPhoto'), findsNothing);
    });

    testWidgets('tapping gallery option in bottom sheet closes it', (
      tester,
    ) async {
      await pumpLocalizedWidget(tester, ProfileHeader(user: testUser));

      await tester.tap(find.byType(DeelAvatar));
      await tester.pumpAndSettle();

      await tester.tap(find.text('profile.chooseFromGallery'));
      await tester.pumpAndSettle();

      expect(find.text('profile.pickPhoto'), findsNothing);
    });

    testWidgets('bottom sheet has two ListTile options', (tester) async {
      await pumpLocalizedWidget(tester, ProfileHeader(user: testUser));

      await tester.tap(find.byType(DeelAvatar));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNWidgets(2));
    });

    testWidgets('formats member since for single-digit month', (tester) async {
      final januaryUser = testUser.copyWith(createdAt: DateTime(2024));
      await pumpLocalizedWidget(tester, ProfileHeader(user: januaryUser));

      // DateFormat.yMMM('en') for January 2024 → "Jan 2024"
      expect(find.textContaining('Jan 2024'), findsOneWidget);
    });

    testWidgets('formats member since for double-digit month', (tester) async {
      final decUser = testUser.copyWith(createdAt: DateTime(2025, 12));
      await pumpLocalizedWidget(tester, ProfileHeader(user: decUser));

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

      await pumpLocalizedWidget(tester, ProfileHeader(user: noAvatarUser));

      final avatar = tester.widget<DeelAvatar>(find.byType(DeelAvatar));
      expect(avatar.imageUrl, isNull);
      expect(avatar.displayName, 'Pieter Bakker');
      expect(find.text('Pieter Bakker'), findsOneWidget);
    });

    testWidgets('member since text includes the key path', (tester) async {
      await pumpLocalizedWidget(tester, ProfileHeader(user: testUser));

      expect(find.textContaining('profile.memberSince'), findsOneWidget);
    });

    testWidgets('renders onEditTap callback on avatar', (tester) async {
      await pumpLocalizedWidget(tester, ProfileHeader(user: testUser));

      final avatar = tester.widget<DeelAvatar>(find.byType(DeelAvatar));
      expect(avatar.onEditTap, isNotNull);
    });
  });
}
