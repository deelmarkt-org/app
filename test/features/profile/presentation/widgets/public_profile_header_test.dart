import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/domain/entities/review_aggregate.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/public_profile_header.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/rating_display.dart';

import '../../../../helpers/pump_app.dart';

final _user = UserEntity(
  id: 'u1',
  displayName: 'Alice Bakker',
  kycLevel: KycLevel.level1,
  createdAt: DateTime(2024, 3, 15),
  badges: const [BadgeType.emailVerified],
);

const _aggregate = ReviewAggregate(
  userId: 'u1',
  averageRating: 4.5,
  totalCount: 12,
  isVisible: true,
);

void main() {
  group('PublicProfileHeader', () {
    testWidgets('renders display name', (tester) async {
      await pumpLocalizedWidget(
        tester,
        PublicProfileHeader(
          user: _user,
          aggregate: const AsyncValue.data(_aggregate),
        ),
      );

      expect(find.text('Alice Bakker'), findsOneWidget);
    });

    testWidgets('renders member-since text', (tester) async {
      await pumpLocalizedWidget(
        tester,
        PublicProfileHeader(
          user: _user,
          aggregate: const AsyncValue.data(_aggregate),
        ),
      );

      // sellerProfile.memberSince returns its key path in test env
      expect(find.textContaining('sellerProfile.memberSince'), findsOneWidget);
    });

    testWidgets('shows RatingDisplay when aggregate data is available', (
      tester,
    ) async {
      await pumpLocalizedWidget(
        tester,
        PublicProfileHeader(
          user: _user,
          aggregate: const AsyncValue.data(_aggregate),
        ),
      );

      expect(find.byType(RatingDisplay), findsOneWidget);
    });

    testWidgets('hides RatingDisplay while aggregate is loading', (
      tester,
    ) async {
      await pumpLocalizedWidget(
        tester,
        PublicProfileHeader(user: _user, aggregate: const AsyncValue.loading()),
      );

      expect(find.byType(RatingDisplay), findsNothing);
    });

    testWidgets('hides RatingDisplay when aggregate has error', (tester) async {
      await pumpLocalizedWidget(
        tester,
        PublicProfileHeader(
          user: _user,
          aggregate: AsyncValue.error(Exception('fail'), StackTrace.empty),
        ),
      );

      expect(find.byType(RatingDisplay), findsNothing);
    });

    testWidgets('renders without badges when list is empty', (tester) async {
      final userNoBadges = UserEntity(
        id: 'u2',
        displayName: 'Bob de Vries',
        kycLevel: KycLevel.level0,
        createdAt: DateTime.utc(2025),
      );

      await pumpLocalizedWidget(
        tester,
        PublicProfileHeader(
          user: userNoBadges,
          aggregate: const AsyncValue.data(ReviewAggregate.empty('u2')),
        ),
      );

      expect(find.text('Bob de Vries'), findsOneWidget);
    });
  });
}
