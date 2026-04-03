import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/domain/entities/category_entity.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/search/presentation/search_providers.dart';
import 'package:deelmarkt/features/search/presentation/widgets/search_initial_view.dart';

const _mockCategories = [
  CategoryEntity(id: 'cat-1', name: 'Voertuigen', icon: 'car'),
  CategoryEntity(id: 'cat-2', name: 'Elektronica', icon: 'device-mobile'),
];

void main() {
  Widget buildView({
    List<String> recentSearches = const [],
    List<CategoryEntity> categories = _mockCategories,
  }) {
    return ProviderScope(
      overrides: [
        useMockDataProvider.overrideWithValue(true),
        topLevelCategoriesProvider.overrideWith((_) async => categories),
      ],
      child: MaterialApp(
        theme: DeelmarktTheme.light,
        home: Scaffold(
          body: SearchInitialView(
            recentSearches: recentSearches,
            onRecentTap: (_) {},
            onRemoveRecent: (_) {},
            onClearAll: () {},
            onCategoryTap: (_) {},
          ),
        ),
      ),
    );
  }

  group('SearchInitialView', () {
    testWidgets('shows popular categories', (tester) async {
      await tester.pumpWidget(buildView());
      await tester.pumpAndSettle();
      expect(find.text('Voertuigen'), findsOneWidget);
      expect(find.text('Elektronica'), findsOneWidget);
    });

    testWidgets('shows recent searches when provided', (tester) async {
      await tester.pumpWidget(buildView(recentSearches: ['fiets', 'auto']));
      await tester.pumpAndSettle();
      expect(find.text('fiets'), findsOneWidget);
      expect(find.text('auto'), findsOneWidget);
    });

    testWidgets('hides recent section when empty', (tester) async {
      await tester.pumpWidget(buildView());
      await tester.pumpAndSettle();
      // Clear all button should not be visible
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('recent items have Semantics', (tester) async {
      await tester.pumpWidget(buildView(recentSearches: ['fiets']));
      await tester.pumpAndSettle();
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('category chips have Semantics', (tester) async {
      await tester.pumpWidget(buildView());
      await tester.pumpAndSettle();
      // Each category chip is wrapped in Semantics
      expect(find.byType(ActionChip), findsNWidgets(2));
    });
  });
}
