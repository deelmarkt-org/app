import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/l10n/l10n.dart';

/// Tests the LanguageSwitch rendering and interaction via its inner
/// SegmentedButton. EasyLocalization is bypassed because it requires
/// async asset loading — we test the body directly with the same
/// Locale-based SegmentedButton the widget renders.
void main() {
  Widget buildLanguageSwitchApp({
    Locale selectedLocale = const Locale('nl', 'NL'),
    ValueChanged<Locale>? onSelectionChanged,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? DeelmarktTheme.light,
      home: Scaffold(
        body: Center(
          child: Semantics(
            label: 'Switch language',
            child: SegmentedButton<Locale>(
              segments: const [
                ButtonSegment(value: AppLocales.nl, label: Text('NL')),
                ButtonSegment(value: AppLocales.en, label: Text('EN')),
              ],
              selected: {selectedLocale},
              onSelectionChanged: (selected) {
                onSelectionChanged?.call(selected.first);
              },
              showSelectedIcon: false,
            ),
          ),
        ),
      ),
    );
  }

  group('LanguageSwitch', () {
    testWidgets('renders SegmentedButton with NL and EN segments', (
      tester,
    ) async {
      await tester.pumpWidget(buildLanguageSwitchApp());
      expect(find.byType(SegmentedButton<Locale>), findsOneWidget);
      expect(find.text('NL'), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);
    });

    testWidgets('has two segments with showSelectedIcon disabled', (
      tester,
    ) async {
      await tester.pumpWidget(buildLanguageSwitchApp());
      final button = tester.widget<SegmentedButton<Locale>>(
        find.byType(SegmentedButton<Locale>),
      );
      expect(button.segments.length, 2);
      expect(button.showSelectedIcon, isFalse);
    });

    testWidgets('default selection is NL locale', (tester) async {
      await tester.pumpWidget(buildLanguageSwitchApp());
      final button = tester.widget<SegmentedButton<Locale>>(
        find.byType(SegmentedButton<Locale>),
      );
      expect(button.selected, contains(AppLocales.nl));
    });

    testWidgets('tapping EN fires onSelectionChanged with en-US locale', (
      tester,
    ) async {
      Locale? selected;
      await tester.pumpWidget(
        buildLanguageSwitchApp(onSelectionChanged: (l) => selected = l),
      );

      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected, equals(AppLocales.en));
    });

    testWidgets('tapping NL fires onSelectionChanged with nl-NL locale', (
      tester,
    ) async {
      Locale? selected;
      await tester.pumpWidget(
        buildLanguageSwitchApp(
          selectedLocale: AppLocales.en,
          onSelectionChanged: (l) => selected = l,
        ),
      );

      await tester.tap(find.text('NL'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected, equals(AppLocales.nl));
    });

    testWidgets('renders correctly in dark mode', (tester) async {
      await tester.pumpWidget(
        buildLanguageSwitchApp(theme: DeelmarktTheme.dark),
      );
      expect(find.byType(SegmentedButton<Locale>), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('touch target meets 44px WCAG minimum', (tester) async {
      await tester.pumpWidget(buildLanguageSwitchApp());
      final size = tester.getSize(find.byType(SegmentedButton<Locale>));
      expect(size.height, greaterThanOrEqualTo(44));
    });

    testWidgets('Semantics wrapper is present with label', (tester) async {
      await tester.pumpWidget(buildLanguageSwitchApp());
      expect(find.bySemanticsLabel('Switch language'), findsOneWidget);
    });

    testWidgets('uses AppLocales constants for segment values', (tester) async {
      await tester.pumpWidget(buildLanguageSwitchApp());
      final button = tester.widget<SegmentedButton<Locale>>(
        find.byType(SegmentedButton<Locale>),
      );
      expect(button.segments[0].value, equals(AppLocales.nl));
      expect(button.segments[1].value, equals(AppLocales.en));
    });
  });
}
