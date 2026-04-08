import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/constants.dart';
import 'package:deelmarkt/widgets/trust/star_row.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('StarRow', () {
    testWidgets('renders 5 star icons', (tester) async {
      await pumpTestWidget(tester, const StarRow(rating: 3));

      expect(find.byType(Icon), findsNWidgets(5));
    });

    testWidgets('fills stars up to rating.round()', (tester) async {
      await pumpTestWidget(tester, const StarRow(rating: 3.4));

      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();

      // First 3 should be filled, last 2 unfilled.
      for (var i = 0; i < 3; i++) {
        expect(
          icons[i].icon,
          PhosphorIcons.star(PhosphorIconsStyle.fill),
          reason: 'Star $i should be filled',
        );
      }
      for (var i = 3; i < 5; i++) {
        expect(
          icons[i].icon,
          PhosphorIcons.star(),
          reason: 'Star $i should be unfilled',
        );
      }
    });

    testWidgets('uses StarSizes.small by default', (tester) async {
      await pumpTestWidget(tester, const StarRow(rating: 1));

      final icon = tester.widget<Icon>(find.byType(Icon).first);
      expect(icon.size, StarSizes.small);
    });

    testWidgets('respects custom size parameter', (tester) async {
      await pumpTestWidget(
        tester,
        const StarRow(rating: 1, size: StarSizes.large),
      );

      final icon = tester.widget<Icon>(find.byType(Icon).first);
      expect(icon.size, StarSizes.large);
    });

    testWidgets('rating 0 renders all unfilled', (tester) async {
      await pumpTestWidget(tester, const StarRow(rating: 0));

      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      for (final icon in icons) {
        expect(icon.icon, PhosphorIcons.star());
      }
    });

    testWidgets('rating 5 renders all filled', (tester) async {
      await pumpTestWidget(tester, const StarRow(rating: 5));

      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      for (final icon in icons) {
        expect(icon.icon, PhosphorIcons.star(PhosphorIconsStyle.fill));
      }
    });
  });
}
