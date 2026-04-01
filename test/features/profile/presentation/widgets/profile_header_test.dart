import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/profile_header.dart';
import 'package:deelmarkt/widgets/badges/deel_avatar.dart';

import '../../../../helpers/pump_app.dart';

void main() {
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
      await pumpTestWidget(tester, ProfileHeader(user: testUser));

      final avatar = tester.widget<DeelAvatar>(find.byType(DeelAvatar));
      expect(avatar.displayName, 'Jan de Vries');
    });

    testWidgets('renders DeelAvatar with large size', (tester) async {
      await pumpTestWidget(tester, ProfileHeader(user: testUser));

      final avatar = tester.widget<DeelAvatar>(find.byType(DeelAvatar));
      expect(avatar.size, DeelAvatarSize.large);
    });

    testWidgets('shows display name as text', (tester) async {
      await pumpTestWidget(tester, ProfileHeader(user: testUser));

      expect(find.text('Jan de Vries'), findsOneWidget);
    });

    testWidgets('shows member since date', (tester) async {
      await pumpTestWidget(tester, ProfileHeader(user: testUser));

      // .tr() returns key path in tests; date is formatted as month/year
      expect(find.textContaining('6/2025'), findsOneWidget);
    });

    testWidgets('shows edit overlay on avatar', (tester) async {
      await pumpTestWidget(tester, ProfileHeader(user: testUser));

      final avatar = tester.widget<DeelAvatar>(find.byType(DeelAvatar));
      expect(avatar.showEditOverlay, isTrue);
    });

    testWidgets('renders with user that has avatar URL', (tester) async {
      final userWithAvatar = testUser.copyWith(
        avatarUrl: 'https://example.com/avatar.jpg',
      );

      await pumpTestWidget(tester, ProfileHeader(user: userWithAvatar));

      final avatar = tester.widget<DeelAvatar>(find.byType(DeelAvatar));
      expect(avatar.imageUrl, 'https://example.com/avatar.jpg');
    });

    testWidgets('tapping avatar opens bottom sheet with image picker options', (
      tester,
    ) async {
      await pumpTestWidget(tester, ProfileHeader(user: testUser));

      await tester.tap(find.byType(DeelAvatar));
      await tester.pumpAndSettle();

      expect(find.text('profile.pickPhoto'), findsOneWidget);
      expect(find.text('profile.takePhoto'), findsOneWidget);
      expect(find.text('profile.chooseFromGallery'), findsOneWidget);
    });

    testWidgets('tapping camera option in bottom sheet closes it', (
      tester,
    ) async {
      await pumpTestWidget(tester, ProfileHeader(user: testUser));

      await tester.tap(find.byType(DeelAvatar));
      await tester.pumpAndSettle();

      await tester.tap(find.text('profile.takePhoto'));
      await tester.pumpAndSettle();

      expect(find.text('profile.pickPhoto'), findsNothing);
    });

    testWidgets('tapping gallery option in bottom sheet closes it', (
      tester,
    ) async {
      await pumpTestWidget(tester, ProfileHeader(user: testUser));

      await tester.tap(find.byType(DeelAvatar));
      await tester.pumpAndSettle();

      await tester.tap(find.text('profile.chooseFromGallery'));
      await tester.pumpAndSettle();

      expect(find.text('profile.pickPhoto'), findsNothing);
    });

    testWidgets('bottom sheet has two ListTile options', (tester) async {
      await pumpTestWidget(tester, ProfileHeader(user: testUser));

      await tester.tap(find.byType(DeelAvatar));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNWidgets(2));
    });
  });
}
