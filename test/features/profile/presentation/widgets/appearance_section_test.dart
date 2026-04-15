import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/core/services/theme_mode_notifier.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/appearance_section.dart';

Future<ProviderContainer> pumpSection(
  WidgetTester tester, {
  Map<String, Object> initialValues = const {},
}) async {
  SharedPreferences.setMockInitialValues(initialValues);
  await initSharedPreferences();

  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(home: Scaffold(body: AppearanceSection())),
    ),
  );
  await tester.pump();

  return tester
      .element(find.byType(AppearanceSection))
      .getInheritedWidgetOfExactType<UncontrolledProviderScope>()!
      .container;
}

void main() {
  group('AppearanceSection', () {
    testWidgets('renders three RadioListTile options', (tester) async {
      await pumpSection(tester);

      expect(find.byType(RadioListTile<ThemeMode>), findsNWidgets(3));
    });

    testWidgets('system option is selected by default', (tester) async {
      final container = await pumpSection(tester);

      expect(container.read(themeModeNotifierProvider), ThemeMode.system);
    });

    testWidgets('tapping dark option updates provider to ThemeMode.dark', (
      tester,
    ) async {
      final container = await pumpSection(tester);

      // Tap the dark tile (second option)
      final tiles = find.byType(RadioListTile<ThemeMode>);
      await tester.tap(tiles.at(1));
      await tester.pump();

      expect(container.read(themeModeNotifierProvider), ThemeMode.dark);
    });

    testWidgets('tapping light option updates provider to ThemeMode.light', (
      tester,
    ) async {
      final container = await pumpSection(tester);

      final tiles = find.byType(RadioListTile<ThemeMode>);
      await tester.tap(tiles.first);
      await tester.pump();

      expect(container.read(themeModeNotifierProvider), ThemeMode.light);
    });

    testWidgets('radio options have inMutuallyExclusiveGroup Semantics', (
      tester,
    ) async {
      await pumpSection(tester);

      final semanticsList =
          tester.widgetList<Semantics>(find.byType(Semantics)).toList();
      final mutuallyExclusive =
          semanticsList
              .where((s) => s.properties.inMutuallyExclusiveGroup == true)
              .toList();

      expect(mutuallyExclusive.length, greaterThanOrEqualTo(3));
    });
  });
}
