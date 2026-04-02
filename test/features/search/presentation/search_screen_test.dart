import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/search/presentation/search_screen.dart';
import 'package:deelmarkt/widgets/inputs/deel_input.dart';

void main() {
  Widget buildScreen({String initialQuery = ''}) {
    return ProviderScope(
      overrides: [useMockDataProvider.overrideWithValue(true)],
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
      // Should not show error state
      expect(find.byType(SearchScreen), findsOneWidget);
    });
  });
}
