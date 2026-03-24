import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/widgets/inputs/deel_search_input.dart';

import 'deel_input_test_helper.dart';

void main() {
  group('DeelSearchInput rendering', () {
    testWidgets('renders magnifying glass prefix icon', (tester) async {
      await tester.pumpWidget(
        buildInputApp(child: const DeelSearchInput(label: 'Search')),
      );
      expect(find.byIcon(PhosphorIconsRegular.magnifyingGlass), findsOneWidget);
    });

    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        buildInputApp(child: const DeelSearchInput(label: 'Search items')),
      );
      expect(find.text('Search items'), findsOneWidget);
    });

    testWidgets('hides clear button when text is empty', (tester) async {
      await tester.pumpWidget(
        buildInputApp(child: const DeelSearchInput(label: 'Search')),
      );
      expect(find.byIcon(PhosphorIconsRegular.x), findsNothing);
    });

    testWidgets('shows clear button when text is present', (tester) async {
      final controller = TextEditingController(text: 'query');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        buildInputApp(
          child: DeelSearchInput(label: 'Search', controller: controller),
        ),
      );
      expect(find.byIcon(PhosphorIconsRegular.x), findsOneWidget);
    });
  });

  group('DeelSearchInput interaction', () {
    testWidgets('typing fires onChanged callback', (tester) async {
      String? changedValue;
      await tester.pumpWidget(
        buildInputApp(
          child: DeelSearchInput(
            label: 'Search',
            onChanged: (v) => changedValue = v,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'hello');
      expect(changedValue, 'hello');
    });

    testWidgets('debounced callback fires after duration', (tester) async {
      String? debouncedValue;
      await tester.pumpWidget(
        buildInputApp(
          child: DeelSearchInput(
            label: 'Search',
            debounceDuration: const Duration(milliseconds: 100),
            onDebouncedChanged: (v) => debouncedValue = v,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'test');
      // Not yet fired
      expect(debouncedValue, isNull);
      // Advance past debounce duration
      await tester.pump(const Duration(milliseconds: 150));
      expect(debouncedValue, 'test');
    });

    testWidgets('clear button clears text and fires onChanged', (tester) async {
      String? changedValue;
      final controller = TextEditingController(text: 'query');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        buildInputApp(
          child: DeelSearchInput(
            label: 'Search',
            controller: controller,
            clearTooltip: 'Clear',
            onChanged: (v) => changedValue = v,
          ),
        ),
      );
      await tester.tap(find.byIcon(PhosphorIconsRegular.x));
      await tester.pump();
      expect(controller.text, isEmpty);
      expect(changedValue, '');
    });

    testWidgets('filter icon shown when onFilterTap provided', (tester) async {
      await tester.pumpWidget(
        buildInputApp(
          child: DeelSearchInput(
            label: 'Search',
            filterTooltip: 'Filter',
            onFilterTap: () {},
          ),
        ),
      );
      expect(find.byIcon(PhosphorIconsRegular.funnelSimple), findsOneWidget);
    });

    testWidgets('filter icon fires onFilterTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildInputApp(
          child: DeelSearchInput(
            label: 'Search',
            filterTooltip: 'Filter',
            onFilterTap: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.byIcon(PhosphorIconsRegular.funnelSimple));
      expect(tapped, isTrue);
    });
  });

  group('DeelSearchInput debounce', () {
    testWidgets('rapid keystrokes produce single debounced call', (
      tester,
    ) async {
      var callCount = 0;
      await tester.pumpWidget(
        buildInputApp(
          child: DeelSearchInput(
            label: 'Search',
            debounceDuration: const Duration(milliseconds: 100),
            onDebouncedChanged: (_) => callCount++,
          ),
        ),
      );
      // Rapid typing
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(find.byType(TextField), 'ab');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(find.byType(TextField), 'abc');
      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 150));
      expect(callCount, 1);
    });
  });

  group('DeelSearchInput accessibility', () {
    testWidgets('clear button meets 44px touch target', (tester) async {
      final controller = TextEditingController(text: 'query');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        buildInputApp(
          child: DeelSearchInput(
            label: 'Search',
            controller: controller,
            clearTooltip: 'Clear',
          ),
        ),
      );
      final clearButton = find.byIcon(PhosphorIconsRegular.x);
      final size = tester.getSize(
        find.ancestor(of: clearButton, matching: find.byType(IconButton)),
      );
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });

    testWidgets('disabled state prevents interaction', (tester) async {
      var changed = false;
      await tester.pumpWidget(
        buildInputApp(
          child: DeelSearchInput(
            label: 'Search',
            enabled: false,
            onChanged: (_) => changed = true,
          ),
        ),
      );
      await tester.tap(find.byType(TextField), warnIfMissed: false);
      expect(changed, isFalse);
    });
  });
}
