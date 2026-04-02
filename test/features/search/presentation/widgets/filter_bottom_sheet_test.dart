import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';
import 'package:deelmarkt/features/search/presentation/widgets/filter_bottom_sheet.dart';

void main() {
  group('FilterBottomSheet', () {
    testWidgets('opens and shows price slider', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [useMockDataProvider.overrideWithValue(true)],
          child: MaterialApp(
            theme: DeelmarktTheme.light,
            home: Scaffold(
              body: Builder(
                builder:
                    (context) => ElevatedButton(
                      onPressed:
                          () => showFilterBottomSheet(
                            context: context,
                            currentFilter: SearchFilter.empty,
                            onApply: (_) {},
                          ),
                      child: const Text('Open'),
                    ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Price range slider should be visible at top of sheet
      expect(find.byType(RangeSlider), findsOneWidget);
    });

    testWidgets('shows condition checkboxes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [useMockDataProvider.overrideWithValue(true)],
          child: MaterialApp(
            theme: DeelmarktTheme.light,
            home: Scaffold(
              body: Builder(
                builder:
                    (context) => ElevatedButton(
                      onPressed:
                          () => showFilterBottomSheet(
                            context: context,
                            currentFilter: SearchFilter.empty,
                            onApply: (_) {},
                          ),
                      child: const Text('Open'),
                    ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsWidgets);
    });
  });
}
