import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';
import 'package:deelmarkt/features/search/presentation/widgets/filter_sort_section.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Widget buildApp({
    required ValueChanged<SearchFilter> onChanged,
    SearchFilter filter = const SearchFilter(),
  }) {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: MaterialApp(
        theme: DeelmarktTheme.light,
        home: Scaffold(
          body: FilterSortSection(filter: filter, onChanged: onChanged),
        ),
      ),
    );
  }

  group('FilterSortSection', () {
    testWidgets('renders a RadioListTile for each SearchSortOrder value', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(onChanged: (_) {}));
      await tester.pumpAndSettle();

      expect(
        find.byType(RadioListTile<SearchSortOrder>),
        findsNWidgets(SearchSortOrder.values.length),
      );
    });

    testWidgets('tapping priceLowHigh tile fires onChanged with that order', (
      tester,
    ) async {
      SearchFilter? changed;
      await tester.pumpWidget(buildApp(onChanged: (f) => changed = f));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              w is RadioListTile<SearchSortOrder> &&
              w.value == SearchSortOrder.priceLowHigh,
        ),
      );
      await tester.pumpAndSettle();

      expect(changed?.sortOrder, SearchSortOrder.priceLowHigh);
    });

    testWidgets('tapping newest tile fires onChanged with newest', (
      tester,
    ) async {
      SearchFilter? changed;
      await tester.pumpWidget(buildApp(onChanged: (f) => changed = f));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byWidgetPredicate(
          (w) =>
              w is RadioListTile<SearchSortOrder> &&
              w.value == SearchSortOrder.newest,
        ),
      );
      await tester.pumpAndSettle();

      expect(changed?.sortOrder, SearchSortOrder.newest);
    });
  });
}
