import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/admin/presentation/widgets/admin_activity_trends_card.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('AdminActivityTrendsCard', () {
    testWidgets('renders title key', (tester) async {
      await pumpTestWidget(tester, const AdminActivityTrendsCard());

      expect(find.text('admin.empty.trends_title'), findsOneWidget);
    });

    testWidgets('renders empty body key', (tester) async {
      await pumpTestWidget(tester, const AdminActivityTrendsCard());

      expect(find.text('admin.empty.trends_empty'), findsOneWidget);
    });
  });
}
