import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/admin/presentation/widgets/admin_empty_state.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('AdminEmptyState', () {
    testWidgets('renders title key text', (tester) async {
      await pumpTestWidget(tester, AdminEmptyState(onRefresh: () {}));

      expect(find.text('admin.empty.title'), findsOneWidget);
    });

    testWidgets('renders subtitle key text', (tester) async {
      await pumpTestWidget(tester, AdminEmptyState(onRefresh: () {}));

      expect(find.text('admin.empty.subtitle'), findsOneWidget);
    });

    testWidgets('renders refresh button with key text', (tester) async {
      await pumpTestWidget(tester, AdminEmptyState(onRefresh: () {}));

      expect(find.text('admin.empty.refresh'), findsOneWidget);
    });

    testWidgets('tap refresh fires onRefresh callback', (tester) async {
      var refreshCalled = false;

      await pumpTestWidget(
        tester,
        AdminEmptyState(onRefresh: () => refreshCalled = true),
      );

      await tester.tap(find.text('admin.empty.refresh'));
      await tester.pumpAndSettle();

      expect(refreshCalled, isTrue);
    });
  });
}
