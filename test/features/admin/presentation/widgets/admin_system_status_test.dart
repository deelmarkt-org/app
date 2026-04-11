import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/admin/presentation/widgets/admin_system_status.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('AdminSystemStatus', () {
    testWidgets('renders title key text', (tester) async {
      await pumpTestWidget(tester, const AdminSystemStatus());

      expect(find.text('admin.system.title'), findsOneWidget);
    });

    testWidgets('renders 3 service status items', (tester) async {
      await pumpTestWidget(tester, const AdminSystemStatus());

      expect(find.text('admin.system.payment_gateway'), findsOneWidget);
      expect(find.text('admin.system.api_endpoints'), findsOneWidget);
      expect(find.text('admin.system.mail_server'), findsOneWidget);
    });

    testWidgets('renders operational status text', (tester) async {
      await pumpTestWidget(tester, const AdminSystemStatus());

      // All 3 services are operational, so 3 instances of the status text
      expect(find.text('admin.system.operational'), findsNWidgets(3));
    });
  });
}
