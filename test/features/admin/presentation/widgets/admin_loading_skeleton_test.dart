import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/admin/presentation/widgets/admin_loading_skeleton.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('AdminLoadingSkeleton', () {
    testWidgets('renders without errors', (tester) async {
      await pumpTestWidget(tester, const AdminLoadingSkeleton());

      // The skeleton should render skeleton boxes for stat cards
      expect(find.byType(AdminLoadingSkeleton), findsOneWidget);
    });
  });
}
