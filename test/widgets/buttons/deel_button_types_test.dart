/// Stability tests for the [DeelButtonVariant] + [DeelButtonSize] enums.
///
/// These enums are part of the design-system public API. Existing call
/// sites (~80 across the codebase) reference values by name; reordering
/// or renaming is a breaking change. This test pins the contract so a
/// rename surfaces here, not in a UI regression.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/widgets/buttons/deel_button_types.dart';

void main() {
  group('DeelButtonVariant', () {
    test('exposes the documented 6 variants in stable order', () {
      expect(DeelButtonVariant.values, [
        DeelButtonVariant.primary,
        DeelButtonVariant.secondary,
        DeelButtonVariant.outline,
        DeelButtonVariant.ghost,
        DeelButtonVariant.destructive,
        DeelButtonVariant.success,
      ]);
    });

    test('canonical .name strings match design-system tokens', () {
      expect(DeelButtonVariant.primary.name, 'primary');
      expect(DeelButtonVariant.secondary.name, 'secondary');
      expect(DeelButtonVariant.outline.name, 'outline');
      expect(DeelButtonVariant.ghost.name, 'ghost');
      expect(DeelButtonVariant.destructive.name, 'destructive');
      expect(DeelButtonVariant.success.name, 'success');
    });
  });

  group('DeelButtonSize', () {
    test('exposes the documented 3 sizes in descending-height order', () {
      expect(DeelButtonSize.values, [
        DeelButtonSize.large,
        DeelButtonSize.medium,
        DeelButtonSize.small,
      ]);
    });

    test('canonical .name strings match the components.md spec', () {
      expect(DeelButtonSize.large.name, 'large');
      expect(DeelButtonSize.medium.name, 'medium');
      expect(DeelButtonSize.small.name, 'small');
    });
  });
}
