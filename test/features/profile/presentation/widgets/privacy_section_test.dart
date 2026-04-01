import 'package:flutter/material.dart';

import 'package:deelmarkt/features/profile/presentation/widgets/privacy_section.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('PrivacySection', () {
    testWidgets('shows export button and delete button', (tester) async {
      await pumpTestWidget(
        tester,
        PrivacySection(
          onExport: () {},
          onDeleteAccount: () {},
          isExporting: false,
          isDeleting: false,
        ),
      );

      expect(find.text('settings.exportData'), findsOneWidget);
      expect(find.text('settings.deleteAccount'), findsOneWidget);
    });

    testWidgets('export button fires onExport', (tester) async {
      var exportCalled = false;
      await pumpTestWidget(
        tester,
        PrivacySection(
          onExport: () => exportCalled = true,
          onDeleteAccount: () {},
          isExporting: false,
          isDeleting: false,
        ),
      );

      await tester.tap(find.text('settings.exportData'));
      await tester.pumpAndSettle();

      expect(exportCalled, isTrue);
    });

    testWidgets('delete button fires onDeleteAccount', (tester) async {
      var deleteCalled = false;
      await pumpTestWidget(
        tester,
        PrivacySection(
          onExport: () {},
          onDeleteAccount: () => deleteCalled = true,
          isExporting: false,
          isDeleting: false,
        ),
      );

      await tester.tap(find.text('settings.deleteAccount'));
      await tester.pumpAndSettle();

      expect(deleteCalled, isTrue);
    });

    testWidgets('loading state disables export button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrivacySection(
              onExport: () {},
              onDeleteAccount: () {},
              isExporting: true,
              isDeleting: false,
            ),
          ),
        ),
      );
      await tester.pump();

      final exportButtons =
          tester.widgetList<DeelButton>(find.byType(DeelButton)).toList();
      final exportButton = exportButtons.firstWhere(
        (b) => b.variant == DeelButtonVariant.outline,
      );
      expect(exportButton.isLoading, isTrue);
    });

    testWidgets('loading state disables delete button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrivacySection(
              onExport: () {},
              onDeleteAccount: () {},
              isExporting: false,
              isDeleting: true,
            ),
          ),
        ),
      );
      await tester.pump();

      final deleteButtons =
          tester.widgetList<DeelButton>(find.byType(DeelButton)).toList();
      final deleteButton = deleteButtons.firstWhere(
        (b) => b.variant == DeelButtonVariant.destructive,
      );
      expect(deleteButton.isLoading, isTrue);
    });
  });
}
