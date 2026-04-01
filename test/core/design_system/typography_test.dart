import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/typography.dart';

void main() {
  group('DeelmarktTypography', () {
    test('fontFamily is PlusJakartaSans', () {
      expect(DeelmarktTypography.fontFamily, 'PlusJakartaSans');
    });

    test('textTheme has all required styles', () {
      const theme = DeelmarktTypography.textTheme;

      expect(theme.displayLarge, isNotNull);
      expect(theme.headlineLarge, isNotNull);
      expect(theme.headlineMedium, isNotNull);
      expect(theme.headlineSmall, isNotNull);
      expect(theme.bodyLarge, isNotNull);
      expect(theme.bodyMedium, isNotNull);
      expect(theme.bodySmall, isNotNull);
      expect(theme.labelLarge, isNotNull);
      expect(theme.labelSmall, isNotNull);
    });

    test('display style matches design tokens', () {
      final display = DeelmarktTypography.textTheme.displayLarge!;

      expect(display.fontSize, 32);
      expect(display.fontWeight, FontWeight.w700);
      expect(display.height, 1.25);
      expect(display.letterSpacing, -0.64);
    });

    test('body-lg style matches design tokens', () {
      final bodyLg = DeelmarktTypography.textTheme.bodyLarge!;

      expect(bodyLg.fontSize, 16);
      expect(bodyLg.fontWeight, FontWeight.w400);
      expect(bodyLg.height, 1.5);
    });

    test('price styles are defined', () {
      expect(DeelmarktTypography.price.fontSize, 20);
      expect(DeelmarktTypography.price.fontWeight, FontWeight.w700);
      expect(DeelmarktTypography.priceSm.fontSize, 16);
      expect(DeelmarktTypography.priceSm.fontWeight, FontWeight.w700);
    });

    test('overline (labelSmall) has uppercase tracking', () {
      final overline = DeelmarktTypography.textTheme.labelSmall!;

      expect(overline.fontSize, 11);
      expect(overline.fontWeight, FontWeight.w600);
      // 0.88 letter spacing for uppercase tracking
      expect(overline.letterSpacing, 0.88);
    });
  });
}
