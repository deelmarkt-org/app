import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/features/admin/presentation/widgets/admin_sidebar_nav_tile.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('AdminSidebarNavTile', () {
    testWidgets('renders label and icon', (tester) async {
      await pumpTestWidget(
        tester,
        AdminSidebarNavTile(
          icon: PhosphorIconsRegular.flag,
          label: 'admin.nav.flagged',
          selected: false,
          onTap: () {},
        ),
      );

      expect(find.text('admin.nav.flagged'), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.flag), findsOneWidget);
    });

    testWidgets('reports selected=true on the wrapping Semantics widget', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        AdminSidebarNavTile(
          icon: PhosphorIconsRegular.flag,
          label: 'admin.nav.flagged',
          selected: true,
          onTap: () {},
        ),
      );

      final semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(AdminSidebarNavTile),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.properties.label, 'admin.nav.flagged');
      expect(semantics.properties.button, true);
      expect(semantics.properties.selected, true);
    });

    testWidgets('reports selected=false when not selected', (tester) async {
      await pumpTestWidget(
        tester,
        AdminSidebarNavTile(
          icon: PhosphorIconsRegular.flag,
          label: 'admin.nav.flagged',
          selected: false,
          onTap: () {},
        ),
      );

      final semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(AdminSidebarNavTile),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.properties.selected, false);
    });

    testWidgets('uses primary surface background when selected', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        AdminSidebarNavTile(
          icon: PhosphorIconsRegular.flag,
          label: 'admin.nav.flagged',
          selected: true,
          onTap: () {},
        ),
      );

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(AdminSidebarNavTile),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, DeelmarktColors.primarySurface);
    });

    testWidgets('uses transparent background when not selected', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        AdminSidebarNavTile(
          icon: PhosphorIconsRegular.flag,
          label: 'admin.nav.flagged',
          selected: false,
          onTap: () {},
        ),
      );

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(AdminSidebarNavTile),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, Colors.transparent);
    });

    testWidgets('fires onTap when tapped', (tester) async {
      var taps = 0;
      await pumpTestWidget(
        tester,
        AdminSidebarNavTile(
          icon: PhosphorIconsRegular.flag,
          label: 'admin.nav.flagged',
          selected: false,
          onTap: () => taps++,
        ),
      );

      await tester.tap(find.text('admin.nav.flagged'));
      await tester.pump();

      expect(taps, 1);
    });
  });
}
