import 'package:deelmarkt/features/profile/presentation/widgets/app_info_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('AppInfoSection', () {
    testWidgets('shows version string', (tester) async {
      await pumpTestWidget(tester, const AppInfoSection(version: '1.2.3'));

      expect(find.text('1.2.3'), findsOneWidget);
    });

    testWidgets('shows version label', (tester) async {
      await pumpTestWidget(tester, const AppInfoSection(version: '1.2.3'));

      expect(find.text('settings.version'), findsOneWidget);
    });

    testWidgets('has licenses link', (tester) async {
      await pumpTestWidget(tester, const AppInfoSection(version: '1.2.3'));

      expect(find.text('settings.licenses'), findsOneWidget);
    });

    testWidgets('licenses row has chevron icon', (tester) async {
      await pumpTestWidget(tester, const AppInfoSection(version: '1.2.3'));

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('renders section header', (tester) async {
      await pumpTestWidget(tester, const AppInfoSection(version: '1.2.3'));

      expect(find.text('settings.appInfo'), findsOneWidget);
    });
  });
}
