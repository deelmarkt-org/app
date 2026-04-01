import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/widgets/trust/trust_banner.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('TrustBanner.escrow rendering', () {
    testWidgets('renders without errors', (tester) async {
      await pumpTestWidget(tester, const TrustBanner.escrow());
      expect(find.byType(TrustBanner), findsOneWidget);
    });

    testWidgets('contains shield icon', (tester) async {
      await pumpTestWidget(tester, const TrustBanner.escrow());
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('shows more info when callback provided', (tester) async {
      var tapped = false;
      await pumpTestWidget(
        tester,
        TrustBanner.escrow(onMoreInfo: () => tapped = true),
      );

      expect(find.byType(TextButton), findsOneWidget);
      await tester.tap(find.byType(TextButton));
      expect(tapped, isTrue);
    });

    testWidgets('hides more info when no callback', (tester) async {
      await pumpTestWidget(tester, const TrustBanner.escrow());
      expect(find.byType(TextButton), findsNothing);
    });
  });

  group('TrustBanner.info rendering', () {
    testWidgets('renders custom title and description', (tester) async {
      await pumpTestWidget(
        tester,
        const TrustBanner.info(
          title: 'Test Title',
          description: 'Test Description',
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
    });

    testWidgets('uses custom icon when provided', (tester) async {
      final customIcon = PhosphorIcons.star(PhosphorIconsStyle.fill);
      await pumpTestWidget(
        tester,
        TrustBanner.info(
          title: 'Stars',
          description: 'High rating',
          icon: customIcon,
        ),
      );

      expect(find.byIcon(customIcon), findsOneWidget);
    });

    testWidgets('uses info icon as default', (tester) async {
      await pumpTestWidget(
        tester,
        const TrustBanner.info(title: 'Info', description: 'Some info'),
      );

      expect(find.byType(Icon), findsWidgets);
    });
  });

  group('TrustBanner dark mode', () {
    testWidgets('renders in dark mode without errors', (tester) async {
      await pumpTestWidget(
        tester,
        const TrustBanner.escrow(),
        theme: DeelmarktTheme.dark,
      );

      expect(find.byType(TrustBanner), findsOneWidget);
    });

    testWidgets('info variant renders in dark mode', (tester) async {
      await pumpTestWidget(
        tester,
        const TrustBanner.info(
          title: 'Dark Mode',
          description: 'Dark mode test',
        ),
        theme: DeelmarktTheme.dark,
      );

      expect(find.text('Dark Mode'), findsOneWidget);
    });
  });
}
