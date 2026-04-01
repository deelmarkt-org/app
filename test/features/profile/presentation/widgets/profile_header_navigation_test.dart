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

  group('ProfileHeader avatar picker wiring (#53)', () {
    testWidgets('edit overlay is enabled on avatar', (tester) async {
      await pumpTestWidget(tester, ProfileHeader(user: testUser));

      final avatar = tester.widget<DeelAvatar>(find.byType(DeelAvatar));
      expect(avatar.showEditOverlay, isTrue);
      expect(avatar.onEditTap, isNotNull);
    });

    testWidgets('tapping avatar opens image picker bottom sheet', (
      tester,
    ) async {
      await pumpTestWidget(tester, ProfileHeader(user: testUser));

      await tester.tap(find.byType(DeelAvatar));
      await tester.pumpAndSettle();

      expect(find.text('profile.pickPhoto'), findsOneWidget);
      expect(find.text('profile.takePhoto'), findsOneWidget);
      expect(find.text('profile.chooseFromGallery'), findsOneWidget);
    });
  });
}
