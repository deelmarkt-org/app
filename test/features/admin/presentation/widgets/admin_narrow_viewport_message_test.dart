import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/admin/presentation/widgets/admin_narrow_viewport_message.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('AdminNarrowViewportMessage', () {
    testWidgets('renders title l10n key', (tester) async {
      await pumpTestScreen(tester, const AdminNarrowViewportMessage());

      expect(find.text('admin.narrow_viewport.title'), findsOneWidget);
    });

    testWidgets('renders subtitle l10n key', (tester) async {
      await pumpTestScreen(tester, const AdminNarrowViewportMessage());

      expect(find.text('admin.narrow_viewport.subtitle'), findsOneWidget);
    });
  });
}
