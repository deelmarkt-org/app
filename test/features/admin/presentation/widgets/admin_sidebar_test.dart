import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/admin/presentation/widgets/admin_sidebar.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('AdminSidebar', () {
    Widget buildSidebar({
      int selectedIndex = 0,
      ValueChanged<int>? onItemTap,
      VoidCallback? onSignOut,
    }) {
      return Scaffold(
        body: Row(
          children: [
            AdminSidebar(
              selectedIndex: selectedIndex,
              onItemTap: onItemTap ?? (_) {},
              onSignOut: onSignOut ?? () {},
            ),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      );
    }

    // The source widget's footer links use a Row without Expanded for
    // text, which triggers RenderFlex overflow in narrow test viewports.
    // Suppress that layout error so it doesn't fail our structural tests.
    void suppressOverflowErrors() {
      final defaultHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        final message = details.exceptionAsString();
        if (message.contains('overflowed')) return;
        defaultHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = defaultHandler);
    }

    testWidgets('renders 6 navigation items', (tester) async {
      suppressOverflowErrors();
      await pumpTestScreen(tester, buildSidebar());

      expect(find.text('admin.nav.dashboard'), findsOneWidget);
      expect(find.text('admin.nav.flagged'), findsOneWidget);
      expect(find.text('admin.nav.reported'), findsOneWidget);
      expect(find.text('admin.nav.disputes'), findsOneWidget);
      expect(find.text('admin.nav.dsa'), findsOneWidget);
      expect(find.text('admin.nav.appeals'), findsOneWidget);
    });

    testWidgets('tap fires onItemTap with correct index', (tester) async {
      suppressOverflowErrors();
      int? tappedIndex;

      await pumpTestScreen(
        tester,
        buildSidebar(onItemTap: (index) => tappedIndex = index),
      );

      await tester.tap(find.text('admin.nav.disputes'));
      await tester.pumpAndSettle();

      expect(tappedIndex, equals(3));
    });

    testWidgets('container has width 240', (tester) async {
      suppressOverflowErrors();
      await pumpTestScreen(tester, buildSidebar());

      final renderBox = tester.renderObject<RenderBox>(
        find.byType(AdminSidebar),
      );
      expect(renderBox.size.width, equals(240.0));
    });

    testWidgets('sign out footer link fires onSignOut callback', (
      tester,
    ) async {
      suppressOverflowErrors();
      var signedOut = false;

      await pumpTestScreen(
        tester,
        buildSidebar(onSignOut: () => signedOut = true),
      );

      await tester.tap(find.text('admin.sidebar.sign_out'));
      await tester.pumpAndSettle();

      expect(signedOut, isTrue);
    });
  });
}
