import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/domain/entities/category_entity.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/search/presentation/search_screen.dart';
import 'package:deelmarkt/features/search/presentation/widgets/search_initial_view.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';
import 'package:deelmarkt/widgets/inputs/deel_input.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildScreen({String initialQuery = ''}) {
    return ProviderScope(
      overrides: [
        useMockDataProvider.overrideWithValue(true),
        sharedPreferencesProvider.overrideWithValue(prefs),
        topLevelCategoriesProvider.overrideWith(
          (_) async => const <CategoryEntity>[],
        ),
      ],
      child: MaterialApp(
        theme: DeelmarktTheme.light,
        home: SearchScreen(initialQuery: initialQuery),
      ),
    );
  }

  group('SearchScreen', () {
    testWidgets('renders search input', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.byType(DeelInput), findsOneWidget);
    });

    testWidgets('shows initial view when no query', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.byType(ErrorState), findsNothing);
    });

    testWidgets('renders with dark theme', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            useMockDataProvider.overrideWithValue(true),
            sharedPreferencesProvider.overrideWithValue(prefs),
            topLevelCategoriesProvider.overrideWith(
              (_) async => const <CategoryEntity>[],
            ),
          ],
          child: MaterialApp(
            theme: DeelmarktTheme.dark,
            home: const SearchScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);
    });

    testWidgets('search input has Semantics', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.byType(Semantics), findsWidgets);
    });
  });
}
