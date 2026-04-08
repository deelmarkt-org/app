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

      testWidgets('shows response time value and l10n label', (tester) async {
        // 15 min < 60 → value '< 1h', label under_1h bucket key
        await pumpTestWidget(tester, ProfileStatsRow(user: buildUser()));

        expect(find.text('< 1h'), findsOneWidget);
        expect(
          find.text('seller_profile.response_time.under_1h'),
          findsOneWidget,
        );
      });
    });

    group('formats response time value correctly', () {
      testWidgets('under 60 minutes → "< 1h"', (tester) async {
        await pumpTestWidget(
          tester,
          ProfileStatsRow(user: buildUser(responseTimeMinutes: 30)),
        );

        expect(find.text('< 1h'), findsOneWidget);
        expect(
          find.text('seller_profile.response_time.under_1h'),
          findsOneWidget,
        );
      });

      testWidgets('exactly 60 minutes → "< 4h"', (tester) async {
        await pumpTestWidget(
          tester,
          ProfileStatsRow(user: buildUser(responseTimeMinutes: 60)),
        );

        expect(find.text('< 4h'), findsOneWidget);
        expect(
          find.text('seller_profile.response_time.under_4h'),
          findsOneWidget,
        );
      });

      testWidgets('90 minutes → "< 4h"', (tester) async {
        await pumpTestWidget(
          tester,
          ProfileStatsRow(user: buildUser(responseTimeMinutes: 90)),
        );

        expect(find.text('< 4h'), findsOneWidget);
        expect(
          find.text('seller_profile.response_time.under_4h'),
          findsOneWidget,
        );
      });

      testWidgets('240 minutes → "< 24h"', (tester) async {
        await pumpTestWidget(
          tester,
          ProfileStatsRow(user: buildUser(responseTimeMinutes: 240)),
        );

        expect(find.text('< 24h'), findsOneWidget);
        expect(
          find.text('seller_profile.response_time.under_24h'),
          findsOneWidget,
        );
      });

      testWidgets('1440+ minutes → "> 24h"', (tester) async {
        await pumpTestWidget(
          tester,
          ProfileStatsRow(user: buildUser(responseTimeMinutes: 1440)),
        );

        expect(find.text('> 24h'), findsOneWidget);
        expect(
          find.text('seller_profile.response_time.over_24h'),
          findsOneWidget,
        );
      });

      testWidgets('null responseTimeMinutes → "-" value + unknown label', (
        tester,
      ) async {
        await pumpTestWidget(
          tester,
          ProfileStatsRow(user: buildUser(responseTimeMinutes: null)),
        );

        expect(find.text('-'), findsOneWidget);
        expect(
          find.text('seller_profile.response_time.unknown'),
          findsOneWidget,
        );
      });
    });

    group('shows dash for null values', () {
      testWidgets('null averageRating shows dash', (tester) async {
        await pumpTestWidget(
          tester,
          ProfileStatsRow(user: buildUser(averageRating: null)),
        );

        expect(find.text('-'), findsOneWidget);
      });

      testWidgets('both null — one dash for rating, one for response time', (
        tester,
      ) async {
        await pumpTestWidget(
          tester,
          ProfileStatsRow(
            user: buildUser(averageRating: null, responseTimeMinutes: null),
          ),
        );

        expect(find.text('-'), findsNWidgets(2));
        expect(
          find.text('seller_profile.response_time.unknown'),
          findsOneWidget,
        );
      });
    });
  });
}
