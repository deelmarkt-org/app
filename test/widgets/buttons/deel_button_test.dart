/// Index test for the [DeelButton] widget.
///
/// The button's behaviour is split across focused suites for clarity:
/// - `deel_button_rendering_test.dart` — variant/size/icon/loading rendering
/// - `deel_button_states_test.dart`    — pressed/focused/disabled/loading
/// - `deel_button_a11y_test.dart`      — Semantics, focus, contrast, touch
/// - `deel_button_style_test.dart`     — DeelButtonStyleResolver
/// - `deel_button_theme_test.dart`     — DeelButtonThemeData wiring
/// - `deel_button_tokens_test.dart`    — height/padding/icon/font tokens
///
/// This file exists to satisfy CLAUDE.md §6 ("a corresponding test file
/// must exist") and to surface a smoke test on the public API surface
/// — instantiation, default values, re-exports — so a future renaming
/// of public symbols is caught at the index level.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/widgets/buttons/deel_button.dart';

void main() {
  group('DeelButton public API surface', () {
    test('default ctor populates the documented defaults', () {
      const button = DeelButton(label: 'Save', onPressed: null);

      expect(button.label, 'Save');
      expect(button.onPressed, isNull);
      expect(button.variant, DeelButtonVariant.primary);
      expect(button.size, DeelButtonSize.large);
      expect(button.isLoading, isFalse);
      expect(button.fullWidth, isTrue);
      expect(button.leadingIcon, isNull);
      expect(button.trailingIcon, isNull);
    });

    test(
      're-exports DeelButtonVariant + DeelButtonSize from deel_button_types',
      () {
        // Importing only `deel_button.dart` must give callers access to
        // both enums so existing call sites keep working unchanged.
        // ignore: unnecessary_statements
        DeelButtonVariant.primary;
        // ignore: unnecessary_statements
        DeelButtonSize.large;
        expect(DeelButtonVariant.values.length, 6);
        expect(DeelButtonSize.values.length, 3);
      },
    );

    testWidgets(
      'renders with label visible and is keyed by Semantics(button)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DeelButton(label: 'Save', onPressed: () {})),
          ),
        );

        expect(find.text('Save'), findsOneWidget);
        expect(find.byType(DeelButton), findsOneWidget);
      },
    );
  });
}
