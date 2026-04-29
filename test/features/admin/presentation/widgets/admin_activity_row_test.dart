import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/admin/domain/entities/activity_item_entity.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_activity_row.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  // In tests, .tr() returns the key path string. Verify icon-mapped types
  // surface their canonical l10n keys.
  ActivityItemEntity item(
    ActivityItemType type, {
    Map<String, String> params = const {},
    DateTime? timestamp,
  }) {
    return ActivityItemEntity(
      id: 'r1',
      type: type,
      params: params,
      timestamp: timestamp ?? DateTime.now().subtract(const Duration(hours: 1)),
    );
  }

  group('AdminActivityRow', () {
    testWidgets('renders title + subtitle l10n keys for listingRemoved', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        AdminActivityRow(item: item(ActivityItemType.listingRemoved)),
      );

      expect(find.text('admin.activity.listingRemoved.title'), findsOneWidget);
      expect(
        find.text('admin.activity.listingRemoved.subtitle'),
        findsOneWidget,
      );
    });

    testWidgets('renders title + subtitle l10n keys for userVerified', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        AdminActivityRow(item: item(ActivityItemType.userVerified)),
      );

      expect(find.text('admin.activity.userVerified.title'), findsOneWidget);
      expect(find.text('admin.activity.userVerified.subtitle'), findsOneWidget);
    });

    testWidgets('renders title + subtitle l10n keys for disputeEscalated', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        AdminActivityRow(item: item(ActivityItemType.disputeEscalated)),
      );

      expect(
        find.text('admin.activity.disputeEscalated.title'),
        findsOneWidget,
      );
      expect(
        find.text('admin.activity.disputeEscalated.subtitle'),
        findsOneWidget,
      );
    });

    testWidgets('renders title + subtitle l10n keys for systemUpdate', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        AdminActivityRow(item: item(ActivityItemType.systemUpdate)),
      );

      expect(find.text('admin.activity.systemUpdate.title'), findsOneWidget);
      expect(find.text('admin.activity.systemUpdate.subtitle'), findsOneWidget);
    });

    testWidgets('formats timestamp <1min as just_now key', (tester) async {
      await pumpTestWidget(
        tester,
        AdminActivityRow(
          item: item(
            ActivityItemType.userVerified,
            timestamp: DateTime.now().subtract(const Duration(seconds: 10)),
          ),
        ),
      );

      expect(find.text('admin.activity.just_now'), findsOneWidget);
    });

    testWidgets('formats timestamp <60min as minutes_ago key', (tester) async {
      await pumpTestWidget(
        tester,
        AdminActivityRow(
          item: item(
            ActivityItemType.userVerified,
            timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
          ),
        ),
      );

      expect(find.text('admin.activity.minutes_ago'), findsOneWidget);
    });

    testWidgets('formats timestamp <24h as hours_ago key', (tester) async {
      await pumpTestWidget(
        tester,
        AdminActivityRow(
          item: item(
            ActivityItemType.userVerified,
            timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          ),
        ),
      );

      expect(find.text('admin.activity.hours_ago'), findsOneWidget);
    });

    testWidgets('formats timestamp ≥24h as days_ago key', (tester) async {
      await pumpTestWidget(
        tester,
        AdminActivityRow(
          item: item(
            ActivityItemType.userVerified,
            timestamp: DateTime.now().subtract(const Duration(days: 3)),
          ),
        ),
      );

      expect(find.text('admin.activity.days_ago'), findsOneWidget);
    });
  });
}
