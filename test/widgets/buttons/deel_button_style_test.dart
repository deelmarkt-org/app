import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/deel_button_theme.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';
import 'package:deelmarkt/widgets/buttons/deel_button_style.dart';
import 'package:deelmarkt/widgets/buttons/deel_button_tokens.dart';

void main() {
  final theme = DeelButtonThemeData.light();

  DeelButtonStyleResolver resolver({
    DeelButtonVariant variant = DeelButtonVariant.primary,
    DeelButtonSize size = DeelButtonSize.medium,
    bool fullWidth = true,
  }) {
    return DeelButtonStyleResolver(
      variant: variant,
      size: size,
      fullWidth: fullWidth,
      theme: theme,
    );
  }

  group('DeelButtonStyleResolver colour resolution', () {
    test('primary background is theme.primaryBackground', () {
      expect(
        resolver().backgroundFor(DeelButtonVariant.primary),
        theme.primaryBackground,
      );
    });

    test('outline background is transparent', () {
      expect(
        resolver().backgroundFor(DeelButtonVariant.outline),
        Colors.transparent,
      );
    });

    test('ghost background is transparent', () {
      expect(
        resolver().backgroundFor(DeelButtonVariant.ghost),
        Colors.transparent,
      );
    });

    test('secondary foreground is theme.secondaryForeground', () {
      expect(
        resolver().foregroundFor(DeelButtonVariant.secondary),
        theme.secondaryForeground,
      );
    });

    test('outline border is theme.outlineBorderColor', () {
      expect(
        resolver().borderColorFor(DeelButtonVariant.outline),
        theme.outlineBorderColor,
      );
    });

    test('non-outline border is transparent', () {
      expect(
        resolver().borderColorFor(DeelButtonVariant.primary),
        Colors.transparent,
      );
    });
  });

  group('DeelButtonStyleResolver style resolution', () {
    test('medium size produces 44px min height', () {
      final style = resolver(size: DeelButtonSize.medium).resolve();
      final minSize = style.minimumSize!.resolve({});
      expect(minSize!.height, DeelButtonTokens.heightMedium);
    });

    test('fullWidth true produces infinity width', () {
      final style = resolver(fullWidth: true).resolve();
      final minSize = style.minimumSize!.resolve({});
      expect(minSize!.width, double.infinity);
    });

    test('fullWidth false produces 0 width', () {
      final style = resolver(fullWidth: false).resolve();
      final minSize = style.minimumSize!.resolve({});
      expect(minSize!.width, 0);
    });

    test('shape uses DeelmarktRadius.lg', () {
      final style = resolver().resolve();
      final shape = style.shape!.resolve({}) as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(DeelmarktRadius.lg));
    });

    test('elevation is always 0', () {
      final style = resolver().resolve();
      expect(style.elevation!.resolve({}), 0);
    });
  });

  group('DeelButtonStyleResolver state resolution', () {
    test('disabled background has reduced alpha', () {
      final style = resolver().resolve();
      final normal = style.backgroundColor!.resolve({});
      final disabled = style.backgroundColor!.resolve({WidgetState.disabled});
      expect(disabled!.a, lessThan(normal!.a));
    });

    test('disabled foreground has reduced alpha', () {
      final style = resolver().resolve();
      final normal = style.foregroundColor!.resolve({});
      final disabled = style.foregroundColor!.resolve({WidgetState.disabled});
      expect(disabled!.a, lessThan(normal!.a));
    });

    test('focused outline border uses primary colour', () {
      final style = resolver(variant: DeelButtonVariant.primary).resolve();
      final shape =
          style.shape!.resolve({WidgetState.focused}) as RoundedRectangleBorder;
      expect(shape.side.color, theme.primaryBackground);
      expect(shape.side.width, 2);
    });
  });
}
