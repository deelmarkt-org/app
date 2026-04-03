import 'package:deelmarkt/features/profile/presentation/widgets/settings_section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('SettingsSectionHeader', () {
    testWidgets('renders title text', (tester) async {
      await pumpTestWidget(
        tester,
        const SettingsSectionHeader(title: 'Test Section'),
      );

      expect(find.text('Test Section'), findsOneWidget);
    });

    testWidgets('has Semantics with header true', (tester) async {
      await pumpTestWidget(
        tester,
        const SettingsSectionHeader(title: 'Heading'),
      );

      final semanticsList = tester.widgetList<Semantics>(
        find.byType(Semantics),
      );
      final hasHeader = semanticsList.any((s) => s.properties.header == true);
      expect(hasHeader, isTrue);
    });

    testWidgets('uses titleMedium text style', (tester) async {
      await pumpTestWidget(
        tester,
        const SettingsSectionHeader(title: 'Styled'),
      );

      final text = tester.widget<Text>(find.text('Styled'));
      expect(text.style?.fontWeight, FontWeight.w600);
    });
  });
}
