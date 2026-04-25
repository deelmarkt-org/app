import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/domain/entities/category_entity.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';
import 'package:deelmarkt/features/search/presentation/search_providers.dart';
import 'package:deelmarkt/features/search/presentation/widgets/filter_category_section.dart';

const _mockCategories = [
  CategoryEntity(id: 'cat-1', name: 'Voertuigen', icon: 'car'),
  CategoryEntity(id: 'cat-2', name: 'Elektronica', icon: 'device-mobile'),
];

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Widget buildApp({
    required ValueChanged<SearchFilter> onChanged,
    SearchFilter filter = const SearchFilter(),
    List<CategoryEntity> categories = _mockCategories,
  }) {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: ProviderScope(
        overrides: [
          useMockDataProvider.overrideWithValue(true),
          // Synchronous override avoids FakeAsync timing issues with the mock
          // repository's Future.delayed — same pattern as search_initial_view_test.
          topLevelCategoriesProvider.overrideWith((_) async => categories),
        ],
        child: MaterialApp(
          theme: DeelmarktTheme.light,
          home: Scaffold(
            body: FilterCategorySection(filter: filter, onChanged: onChanged),
          ),
        ),
      ),
    );
  }

  group('FilterCategorySection', () {
    testWidgets('renders a FilterChip for each category', (tester) async {
      await tester.pumpWidget(buildApp(onChanged: (_) {}));
      await tester.pumpAndSettle();

      expect(
        find.byType(FilterChip),
        findsNWidgets(_mockCategories.length),
        reason: 'one chip per category',
      );
    });

    testWidgets('tapping a chip fires onChanged with that category id', (
      tester,
    ) async {
      SearchFilter? changed;
      await tester.pumpWidget(buildApp(onChanged: (f) => changed = f));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Voertuigen'));
      await tester.pumpAndSettle();

      expect(changed?.categoryId, 'cat-1');
    });

    testWidgets('chip for current categoryId renders as selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          onChanged: (_) {},
          filter: const SearchFilter(categoryId: 'cat-2'),
        ),
      );
      await tester.pumpAndSettle();

      final chip = tester.widget<FilterChip>(
        find.ancestor(
          of: find.text('Elektronica'),
          matching: find.byType(FilterChip),
        ),
      );
      expect(
        chip.selected,
        isTrue,
        reason: 'chip for current categoryId should be selected',
      );
    });

    testWidgets('tapping selected chip fires onChanged with null categoryId', (
      tester,
    ) async {
      SearchFilter? changed;
      await tester.pumpWidget(
        buildApp(
          onChanged: (f) => changed = f,
          filter: const SearchFilter(categoryId: 'cat-1'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Voertuigen')); // cat-1 is already selected
      await tester.pumpAndSettle();

      expect(
        changed?.categoryId,
        isNull,
        reason: 're-tapping selected chip should deselect it',
      );
    });
  });
}
