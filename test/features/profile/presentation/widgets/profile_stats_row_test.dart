import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/profile_stats_row.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  UserEntity buildUser({
    double? averageRating = 4.7,
    int? responseTimeMinutes = 15,
    int reviewCount = 23,
  }) {
    return UserEntity(
      id: 'user-001',
      displayName: 'Jan de Vries',
      kycLevel: KycLevel.level1,
      createdAt: DateTime(2025, 6),
      averageRating: averageRating,
      reviewCount: reviewCount,
      responseTimeMinutes: responseTimeMinutes,
    );
  }

  group('ProfileStatsRow', () {
    group('renders 3 stats', () {
      testWidgets('shows sold count', (tester) async {
        await pumpTestWidget(tester, ProfileStatsRow(user: buildUser()));

        // Sold count is hardcoded to '0'
        expect(find.text('0'), findsOneWidget);
        // .tr() returns the key path in tests
        expect(find.text('profile.sold'), findsOneWidget);
      });

      testWidgets('shows reviews rating', (tester) async {
        await pumpTestWidget(tester, ProfileStatsRow(user: buildUser()));

        expect(find.text('4.7'), findsOneWidget);
        expect(find.text('profile.reviews'), findsOneWidget);
      });

      testWidgets('shows response time', (tester) async {
        await pumpTestWidget(tester, ProfileStatsRow(user: buildUser()));

        expect(find.text('15m'), findsOneWidget);
        expect(find.text('profile.response_time'), findsOneWidget);
      });
    });

    group('formats response time correctly', () {
      testWidgets('minutes under 60 show as Xm', (tester) async {
        await pumpTestWidget(
          tester,
          ProfileStatsRow(user: buildUser(responseTimeMinutes: 30)),
        );

        expect(find.text('30m'), findsOneWidget);
      });

      testWidgets('60 minutes shows as 1h', (tester) async {
        await pumpTestWidget(
          tester,
          ProfileStatsRow(user: buildUser(responseTimeMinutes: 60)),
        );

        expect(find.text('1h'), findsOneWidget);
      });

      testWidgets('90 minutes rounds to 2h', (tester) async {
        await pumpTestWidget(
          tester,
          ProfileStatsRow(user: buildUser(responseTimeMinutes: 90)),
        );

        expect(find.text('2h'), findsOneWidget);
      });

      testWidgets('120 minutes shows as 2h', (tester) async {
        await pumpTestWidget(
          tester,
          ProfileStatsRow(user: buildUser(responseTimeMinutes: 120)),
        );

        expect(find.text('2h'), findsOneWidget);
      });
    });

    group('shows dash for null values', () {
      testWidgets('null averageRating shows dash', (tester) async {
        await pumpTestWidget(
          tester,
          ProfileStatsRow(user: buildUser(averageRating: null)),
        );

        // One dash for rating, one for response time if also null
        expect(find.text('-'), findsOneWidget);
      });

      testWidgets('null responseTimeMinutes shows dash', (tester) async {
        await pumpTestWidget(
          tester,
          ProfileStatsRow(user: buildUser(responseTimeMinutes: null)),
        );

        expect(find.text('-'), findsOneWidget);
      });

      testWidgets('both null show two dashes', (tester) async {
        await pumpTestWidget(
          tester,
          ProfileStatsRow(
            user: buildUser(averageRating: null, responseTimeMinutes: null),
          ),
        );

        expect(find.text('-'), findsNWidgets(2));
      });
    });
  });
}
