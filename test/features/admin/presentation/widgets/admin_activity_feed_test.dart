import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/admin/domain/entities/activity_item_entity.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_activity_feed.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  // In tests, .tr() returns the key path string (no translation loaded).
  // So we verify that the correct l10n key paths are rendered.
  final testItems = [
    ActivityItemEntity(
      id: 'a1',
      type: ActivityItemType.listingRemoved,
      params: const {'listingId': '4321', 'moderator': 'Moderator A'},
      timestamp: DateTime(2026),
    ),
    ActivityItemEntity(
      id: 'a2',
      type: ActivityItemType.userVerified,
      params: const {'userId': 'jansen_m', 'method': 'iDIN'},
      timestamp: DateTime(2026),
    ),
  ];

  group('AdminActivityFeed', () {
    testWidgets('renders title key text', (tester) async {
      await pumpTestWidget(tester, AdminActivityFeed(items: testItems));

      expect(find.text('admin.activity.title'), findsOneWidget);
    });

    testWidgets('renders listingRemoved title l10n key', (tester) async {
      await pumpTestWidget(tester, AdminActivityFeed(items: testItems));

      expect(find.text('admin.activity.listingRemoved.title'), findsOneWidget);
    });

    testWidgets('renders userVerified title l10n key', (tester) async {
      await pumpTestWidget(tester, AdminActivityFeed(items: testItems));

      expect(find.text('admin.activity.userVerified.title'), findsOneWidget);
    });

    testWidgets('renders listingRemoved subtitle l10n key', (tester) async {
      await pumpTestWidget(tester, AdminActivityFeed(items: testItems));

      expect(
        find.text('admin.activity.listingRemoved.subtitle'),
        findsOneWidget,
      );
    });

    testWidgets('renders userVerified subtitle l10n key', (tester) async {
      await pumpTestWidget(tester, AdminActivityFeed(items: testItems));

      expect(find.text('admin.activity.userVerified.subtitle'), findsOneWidget);
    });

    testWidgets('renders empty list without error', (tester) async {
      await pumpTestWidget(tester, const AdminActivityFeed(items: []));

      expect(find.text('admin.activity.title'), findsOneWidget);
    });
  });
}
