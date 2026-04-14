import 'package:deelmarkt/features/auth/presentation/widgets/consent_checkboxes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject({
    bool termsAccepted = false,
    bool privacyAccepted = false,
    ValueChanged<bool>? onTermsChanged,
    ValueChanged<bool>? onPrivacyChanged,
    bool enabled = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ConsentCheckboxes(
          termsAccepted: termsAccepted,
          privacyAccepted: privacyAccepted,
          onTermsChanged: onTermsChanged ?? (_) {},
          onPrivacyChanged: onPrivacyChanged ?? (_) {},
          enabled: enabled,
        ),
      ),
    );
  }

  group('ConsentCheckboxes', () {
    testWidgets('renders two CheckboxListTile widgets', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(CheckboxListTile), findsNWidgets(2));
    });

    testWidgets('calls onTermsChanged when terms checkbox is toggled', (
      tester,
    ) async {
      bool? captured;
      await tester.pumpWidget(
        buildSubject(onTermsChanged: (v) => captured = v),
      );

      // Tap the Checkbox widget directly (leading position) to avoid
      // the InkWell link inside the title Wrap intercepting the gesture.
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.first);
      await tester.pump();

      expect(captured, isTrue);
    });

    testWidgets('calls onPrivacyChanged when privacy checkbox is toggled', (
      tester,
    ) async {
      bool? captured;
      await tester.pumpWidget(
        buildSubject(onPrivacyChanged: (v) => captured = v),
      );

      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.last);
      await tester.pump();

      expect(captured, isTrue);
    });

    testWidgets('checkboxes are disabled when enabled is false', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(enabled: false));

      final tiles =
          tester
              .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
              .toList();

      expect(tiles.every((t) => t.onChanged == null), isTrue);
    });

    testWidgets('link widgets have Semantics with link: true', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      final semanticsList =
          tester.widgetList<Semantics>(find.byType(Semantics)).toList();
      final linkSemantics =
          semanticsList.where((s) => s.properties.link == true).toList();

      expect(linkSemantics.length, greaterThanOrEqualTo(2));
    });

    testWidgets('reflects termsAccepted initial value', (tester) async {
      await tester.pumpWidget(buildSubject(termsAccepted: true));

      final tile = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile).first,
      );
      expect(tile.value, isTrue);
    });

    testWidgets('reflects privacyAccepted initial value', (tester) async {
      await tester.pumpWidget(buildSubject(privacyAccepted: true));

      final tile = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile).last,
      );
      expect(tile.value, isTrue);
    });
  });
}
