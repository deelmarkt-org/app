import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/rating_input.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('RatingInput', () {
    testWidgets('renders 5 stars', (tester) async {
      await pumpTestWidget(tester, RatingInput(value: 0, onChanged: (_) {}));

      expect(find.byType(Icon), findsNWidgets(5));
    });

    testWidgets('filled stars match the value', (tester) async {
      await pumpTestWidget(tester, RatingInput(value: 3, onChanged: (_) {}));

      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      // First 3 stars are filled (warning colour)
      for (var i = 0; i < 3; i++) {
        expect(icons[i].color, DeelmarktColors.warning);
      }
      // Last 2 are outline (neutral)
      for (var i = 3; i < 5; i++) {
        expect(icons[i].color, DeelmarktColors.neutral300);
      }
    });

    testWidgets('tapping a star invokes onChanged with correct value', (
      tester,
    ) async {
      double? tappedValue;
      await pumpTestWidget(
        tester,
        RatingInput(value: 0, onChanged: (v) => tappedValue = v),
      );

      // Tap the third star (index 2)
      final stars = find.byType(InkResponse);
      await tester.tap(stars.at(2));
      expect(tappedValue, 3.0);
    });

    testWidgets('readOnly mode does not invoke onChanged', (tester) async {
      var tapped = false;
      await pumpTestWidget(
        tester,
        RatingInput(value: 3, readOnly: true, onChanged: (_) => tapped = true),
      );

      final stars = find.byType(InkResponse);
      await tester.tap(stars.at(4));
      expect(tapped, isFalse);
    });

    testWidgets('each star meets 44×44 minimum tap target', (tester) async {
      await pumpTestWidget(tester, RatingInput(value: 0, onChanged: (_) {}));

      // Each InkResponse wraps a SizedBox(48×48) — verify tap areas
      final detectors = find.descendant(
        of: find.byType(RatingInput),
        matching: find.byType(InkResponse),
      );

      for (var i = 0; i < 5; i++) {
        final size = tester.getSize(detectors.at(i));
        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, greaterThanOrEqualTo(44));
      }
    });

    testWidgets('has Semantics with value per star', (tester) async {
      await pumpTestWidget(tester, RatingInput(value: 2, onChanged: (_) {}));

      // Star 1 and 2 should be "selected", 3-5 "unselected"
      final semanticsWidgets = tester.widgetList<Semantics>(
        find.descendant(
          of: find.byType(RatingInput),
          matching: find.byType(Semantics),
        ),
      );

      final buttonSemantics =
          semanticsWidgets.where((s) => s.properties.button == true).toList();
      expect(buttonSemantics, hasLength(5));
      expect(buttonSemantics[0].properties.value, 'selected');
      expect(buttonSemantics[1].properties.value, 'selected');
      expect(buttonSemantics[2].properties.value, 'unselected');
    });

    testWidgets('is wrapped in RepaintBoundary', (tester) async {
      await pumpTestWidget(tester, RatingInput(value: 0, onChanged: (_) {}));

      expect(
        find.ancestor(
          of: find.byType(Row),
          matching: find.byType(RepaintBoundary),
        ),
        findsWidgets,
      );
    });
  });
}
