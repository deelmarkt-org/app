import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';
import 'package:deelmarkt/widgets/buttons/deel_button_tokens.dart';

void main() {
  group('DeelButtonTokens heights', () {
    test('large = 52', () {
      expect(DeelButtonTokens.heightFor(DeelButtonSize.large), 52);
    });

    test('medium = 44 (WCAG minimum)', () {
      expect(DeelButtonTokens.heightFor(DeelButtonSize.medium), 44);
    });

    test('small = 36', () {
      expect(DeelButtonTokens.heightFor(DeelButtonSize.small), 36);
    });
  });

  group('DeelButtonTokens font sizes', () {
    test('large = 16', () {
      expect(DeelButtonTokens.fontSizeFor(DeelButtonSize.large), 16);
    });

    test('medium = 14', () {
      expect(DeelButtonTokens.fontSizeFor(DeelButtonSize.medium), 14);
    });

    test('small = 13', () {
      expect(DeelButtonTokens.fontSizeFor(DeelButtonSize.small), 13);
    });
  });

  group('DeelButtonTokens icon sizes', () {
    test('large = 20', () {
      expect(DeelButtonTokens.iconSizeFor(DeelButtonSize.large), 20);
    });

    test('medium = 18', () {
      expect(DeelButtonTokens.iconSizeFor(DeelButtonSize.medium), 18);
    });

    test('small = 16', () {
      expect(DeelButtonTokens.iconSizeFor(DeelButtonSize.small), 16);
    });
  });

  group('DeelButtonTokens padding', () {
    test('large = Spacing.s6 (24)', () {
      expect(DeelButtonTokens.paddingFor(DeelButtonSize.large), Spacing.s6);
    });

    test('medium = Spacing.s4 (16)', () {
      expect(DeelButtonTokens.paddingFor(DeelButtonSize.medium), Spacing.s4);
    });

    test('small = Spacing.s3 (12)', () {
      expect(DeelButtonTokens.paddingFor(DeelButtonSize.small), Spacing.s3);
    });
  });
}
