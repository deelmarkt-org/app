import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/sold_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject({required ThemeMode themeMode}) {
    return MaterialApp(
      themeMode: themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        body: SoldOverlay(
          child: Container(width: 300, height: 200, color: Colors.green),
        ),
      ),
    );
  }

  group('SoldOverlay — dark mode regression (issue #156)', () {
    testWidgets('renders sold badge text in light mode', (tester) async {
      await tester.pumpWidget(buildSubject(themeMode: ThemeMode.light));
      await tester.pump();
      expect(find.textContaining('listing_detail.soldBadge'), findsOneWidget);
    });

    testWidgets('renders sold badge text in dark mode', (tester) async {
      await tester.pumpWidget(buildSubject(themeMode: ThemeMode.dark));
      await tester.pump();
      expect(find.textContaining('listing_detail.soldBadge'), findsOneWidget);
    });

    testWidgets(
      'badge text color is white in both modes (scrim is always dark)',
      (tester) async {
        for (final mode in [ThemeMode.light, ThemeMode.dark]) {
          await tester.pumpWidget(buildSubject(themeMode: mode));
          await tester.pump();

          final textWidget = tester.widget<Text>(
            find.textContaining('listing_detail.soldBadge'),
          );
          final effectiveColor = textWidget.style?.color;
          expect(
            effectiveColor,
            DeelmarktColors.white,
            reason:
                'Badge text must be white on the dark scrim in $mode — '
                'do not replace with colorScheme.onSurface (breaks contrast in '
                'dark mode)',
          );
        }
      },
    );
  });
}
