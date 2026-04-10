import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/admin/domain/entities/activity_item_entity.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_activity_feed.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  final testItems = [
    ActivityItemEntity(
      id: 'a1',
      type: ActivityItemType.listingRemoved,
      title: 'Item removed',
      subtitle: 'Policy violation',
      timestamp: DateTime(2026),
    ),
    ActivityItemEntity(
      id: 'a2',
      type: ActivityItemType.userVerified,
      title: 'User verified',
      subtitle: 'KYC passed',
      timestamp: DateTime(2026),
    ),
  ];

  group('AdminActivityFeed', () {
    testWidgets('renders title key text', (tester) async {
      await pumpTestWidget(tester, AdminActivityFeed(items: testItems));

      expect(find.text('admin.activity.title'), findsOneWidget);
    });

    testWidgets('renders activity item titles', (tester) async {
      await pumpTestWidget(tester, AdminActivityFeed(items: testItems));

      expect(find.text('Item removed'), findsOneWidget);
      expect(find.text('User verified'), findsOneWidget);
    });

    testWidgets('renders activity item subtitles', (tester) async {
      await pumpTestWidget(tester, AdminActivityFeed(items: testItems));

      expect(find.text('Policy violation'), findsOneWidget);
      expect(find.text('KYC passed'), findsOneWidget);
    });
  });
}
