import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/widgets/buttons/deel_button.dart';

import 'deel_button_test_helper.dart';

void main() {
  group('DeelButton states', () {
    testWidgets('onPressed callback fires on tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildButtonApp(
          button: DeelButton(label: 'Tap me', onPressed: () => tapped = true),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isTrue);
    });

    testWidgets('null onPressed disables the button', (tester) async {
      await tester.pumpWidget(
        buildButtonApp(
          button: const DeelButton(label: 'Disabled', onPressed: null),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('loading state shows CircularProgressIndicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildButtonApp(
          button: DeelButton(
            label: 'Loading',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('loading state disables tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildButtonApp(
          button: DeelButton(
            label: 'Loading',
            onPressed: () => tapped = true,
            isLoading: true,
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isFalse);
    });

    testWidgets('disabled button still has correct label in semantics', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildButtonApp(
          button: const DeelButton(label: 'Save', onPressed: null),
        ),
      );

      expect(find.bySemanticsLabel('Save'), findsOneWidget);
    });
  });

  group('DeelButton icons', () {
    testWidgets('renders leading icon', (tester) async {
      await tester.pumpWidget(
        buildButtonApp(
          button: DeelButton(
            label: 'Save',
            onPressed: () {},
            leadingIcon: Icons.save,
          ),
        ),
      );

      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('renders trailing icon', (tester) async {
      await tester.pumpWidget(
        buildButtonApp(
          button: DeelButton(
            label: 'Next',
            onPressed: () {},
            trailingIcon: Icons.arrow_forward,
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('renders both leading and trailing icons', (tester) async {
      await tester.pumpWidget(
        buildButtonApp(
          button: DeelButton(
            label: 'Action',
            onPressed: () {},
            leadingIcon: Icons.star,
            trailingIcon: Icons.chevron_right,
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });

  group('DeelButton animation', () {
    testWidgets('AnimatedSwitcher crossfades between label and spinner', (
      tester,
    ) async {
      var isLoading = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildButtonApp(
              button: DeelButton(
                label: 'Save',
                onPressed: () => setState(() => isLoading = true),
                isLoading: isLoading,
              ),
            );
          },
        ),
      );

      expect(find.text('Save'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('reduced motion uses Duration.zero', (tester) async {
      await tester.pumpWidget(
        buildButtonApp(
          disableAnimations: true,
          button: DeelButton(label: 'Save', onPressed: () {}, isLoading: true),
        ),
      );

      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
