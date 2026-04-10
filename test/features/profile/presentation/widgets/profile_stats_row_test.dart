import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/profile_stats_row.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  // .tr() returns the key path in test environment (no real l10n loaded).
  // Short value keys: seller_profile.response_time.short_under_1h → "< 1h" in prod
  // Label keys:       seller_profile.response_time.under_1h → "Responds within 1 hour" in prod

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

        expect(find.text('0'), findsOneWidget);
        expect(find.text('profile.sold'), findsOneWidget);
      });

      testWidgets('shows reviews rating', (tester) async {
        await pumpTestWidget(tester, ProfileStatsRow(user: buildUser()));

        expect(find.text('4.7'), findsOneWidget);
        expect(find.text('profile.reviews'), findsOneWidget);
      });

      testWidgets('shows response time short value and label', (tester) async {
        // 15 min < 60 → short_under_1h + under_1h
        await pumpTestWidget(tester, ProfileStatsRow(user: buildUser()));

        expect(
          find.text('seller_profile.response_time.short_under_1h'),
          findsOneWidget,
        );
        expect(
          find.text('seller_profile.response_time.under_1h'),
          findsOneWidget,
        );
      });
    });

    group('formats response time using l10n buckets', () {
      testWidgets('under 60 minutes → short_under_1h + under_1h', (
        tester,
      ) async {
        await pumpTestWidget(
          tester,
          ProfileStatsRow(user: buildUser(responseTimeMinutes: 30)),
        );

        expect(
          find.text('seller_profile.response_time.short_under_1h'),
          findsOneWidget,
        );
        expect(
          find.text('seller_profile.response_time.under_1h'),
          findsOneWidget,
        );
      });

      testWidgets('60 minutes → short_under_4h + under_4h', (tester) async {
        await pumpTestWidget(
          tester,
          ProfileStatsRow(user: buildUser(responseTimeMinutes: 60)),
        );

        expect(
          find.text('seller_profile.response_time.short_under_4h'),
          findsOneWidget,
        );
        expect(
          find.text('seller_profile.response_time.under_4h'),
          findsOneWidget,
        );
      });

      testWidgets('240 minutes → short_under_24h + under_24h', (tester) async {
        await pumpTestWidget(
          tester,
          ProfileStatsRow(user: buildUser(responseTimeMinutes: 240)),
        );

        expect(
          find.text('seller_profile.response_time.short_under_24h'),
          findsOneWidget,
        );
        expect(
          find.text('seller_profile.response_time.under_24h'),
          findsOneWidget,
        );
      });

      testWidgets('1440+ minutes → short_over_24h + over_24h', (tester) async {
        await pumpTestWidget(
          tester,
          ProfileStatsRow(user: buildUser(responseTimeMinutes: 1440)),
        );

        expect(
          find.text('seller_profile.response_time.short_over_24h'),
          findsOneWidget,
        );
        expect(
          find.text('seller_profile.response_time.over_24h'),
          findsOneWidget,
        );
      });

      testWidgets('null minutes → dash value + unknown label', (tester) async {
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

      testWidgets('both null — two dashes', (tester) async {
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
