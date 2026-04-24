import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';
import 'package:deelmarkt/features/search/presentation/widgets/filter_panel.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  /// Tall viewport so the full filter panel (5 sections + actions row)
  /// materialises without scrolling — `FilterPanel` uses a `ListView`
  /// which lazy-builds only widgets inside the viewport.
  void setTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1.0;
  }

  Widget buildApp({
    required FilterPanelVariant variant,
    required ValueChanged<SearchFilter> onApply,
    SearchFilter filter = const SearchFilter(query: 'fiets'),
  }) {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: ProviderScope(
        overrides: [useMockDataProvider.overrideWithValue(true)],
        child: MaterialApp(
          theme: DeelmarktTheme.light,
          home: Scaffold(
            body: FilterPanel(
              filter: filter,
              onApply: onApply,
              variant: variant,
            ),
          ),
        ),
      ),
    );
  }

  group('FilterPanel — sheet variant', () {
    testWidgets('renders Reset + Apply (2 DeelButtons in actions row)', (
      tester,
    ) async {
      setTallViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        buildApp(variant: FilterPanelVariant.sheet, onApply: (_) {}),
      );
      await tester.pumpAndSettle();

      // Sheet has Reset + Apply → 2 DeelButtons at the bottom.
      expect(find.byType(DeelButton), findsNWidgets(2));
      await tester.pump(const Duration(seconds: 30)); // drain mock timers
    });

    testWidgets('mutation does NOT fire onApply until Apply tapped', (
      tester,
    ) async {
      setTallViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SearchFilter? applied;
      await tester.pumpWidget(
        buildApp(
          variant: FilterPanelVariant.sheet,
          onApply: (f) => applied = f,
        ),
      );
      await tester.pumpAndSettle();

      // Change sort order via the RadioListTile (bypasses l10n text matching).
      await tester.tap(
        find
            .byWidgetPredicate(
              (w) =>
                  w is RadioListTile<SearchSortOrder> &&
                  w.value == SearchSortOrder.priceLowHigh,
            )
            .first,
      );
      await tester.pumpAndSettle();

      expect(applied, isNull, reason: 'sheet buffers until Apply tapped');
      await tester.pump(const Duration(seconds: 30)); // drain mock timers
    });
  });

  group('FilterPanel — sidebar variant', () {
    testWidgets('renders only Reset (1 DeelButton, no Apply footer)', (
      tester,
    ) async {
      setTallViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        buildApp(variant: FilterPanelVariant.sidebar, onApply: (_) {}),
      );
      await tester.pumpAndSettle();

      // Sidebar drops the Apply button because mutations apply live.
      expect(find.byType(DeelButton), findsOneWidget);
      await tester.pump(const Duration(seconds: 30)); // drain mock timers
    });

    testWidgets('every mutation fires onApply live', (tester) async {
      setTallViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final applied = <SearchFilter>[];
      await tester.pumpWidget(
        buildApp(variant: FilterPanelVariant.sidebar, onApply: applied.add),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find
            .byWidgetPredicate(
              (w) =>
                  w is RadioListTile<SearchSortOrder> &&
                  w.value == SearchSortOrder.priceLowHigh,
            )
            .first,
      );
      await tester.pumpAndSettle();

      expect(applied, isNotEmpty, reason: 'sidebar applies live');
      expect(applied.last.sortOrder, SearchSortOrder.priceLowHigh);
      await tester.pump(const Duration(seconds: 30)); // drain mock timers
    });
  });
}
