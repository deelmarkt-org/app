import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/features/home/presentation/widgets/category_tint_colors.dart';

void main() {
  group('categoryTintFor', () {
    const allCategoryIds = [
      'cat-electronics',
      'cat-clothing',
      'cat-home',
      'cat-sport',
      'cat-vehicles',
      'cat-kids',
      'cat-services',
      'cat-other',
    ];

    group('light mode', () {
      const brightness = Brightness.light;

      test('returns non-null record for every known category', () {
        for (final id in allCategoryIds) {
          final tint = categoryTintFor(id, brightness);
          expect(tint.background, isNotNull, reason: '$id background');
          expect(tint.iconBackground, isNotNull, reason: '$id iconBackground');
          expect(tint.iconForeground, isNotNull, reason: '$id iconForeground');
        }
      });

      test('cat-electronics uses secondary blue', () {
        final tint = categoryTintFor('cat-electronics', brightness);
        expect(tint.background, DeelmarktColors.secondarySurface);
        expect(tint.iconBackground, DeelmarktColors.secondarySurface);
        expect(tint.iconForeground, DeelmarktColors.secondary);
      });

      test('cat-clothing uses error red', () {
        final tint = categoryTintFor('cat-clothing', brightness);
        expect(tint.background, DeelmarktColors.errorSurface);
        expect(tint.iconBackground, DeelmarktColors.errorSurface);
        expect(tint.iconForeground, DeelmarktColors.error);
      });

      test('cat-home uses success green', () {
        final tint = categoryTintFor('cat-home', brightness);
        expect(tint.background, DeelmarktColors.successSurface);
        expect(tint.iconBackground, DeelmarktColors.successSurface);
        expect(tint.iconForeground, DeelmarktColors.success);
      });

      test('cat-sport uses primary orange', () {
        final tint = categoryTintFor('cat-sport', brightness);
        expect(tint.background, DeelmarktColors.primarySurface);
        expect(tint.iconBackground, DeelmarktColors.primarySurface);
        expect(tint.iconForeground, DeelmarktColors.primary);
      });

      test('cat-vehicles uses info blue', () {
        final tint = categoryTintFor('cat-vehicles', brightness);
        expect(tint.background, DeelmarktColors.infoSurface);
        expect(tint.iconBackground, DeelmarktColors.infoSurface);
        expect(tint.iconForeground, DeelmarktColors.info);
      });

      test('cat-kids uses accent purple', () {
        final tint = categoryTintFor('cat-kids', brightness);
        expect(tint.background, DeelmarktColors.accentPurpleSurface);
        expect(tint.iconBackground, DeelmarktColors.accentPurpleSurface);
        expect(tint.iconForeground, DeelmarktColors.accentPurple);
      });

      test('cat-services uses neutral grey', () {
        final tint = categoryTintFor('cat-services', brightness);
        expect(tint.background, DeelmarktColors.neutral100);
        expect(tint.iconBackground, DeelmarktColors.neutral100);
        expect(tint.iconForeground, DeelmarktColors.neutral700);
      });

      test('cat-other uses neutral grey', () {
        final tint = categoryTintFor('cat-other', brightness);
        expect(tint.background, DeelmarktColors.neutral100);
        expect(tint.iconBackground, DeelmarktColors.neutral100);
        expect(tint.iconForeground, DeelmarktColors.neutral700);
      });

      test('unknown category returns fallback', () {
        final tint = categoryTintFor('cat-unknown', brightness);
        expect(tint.background, DeelmarktColors.neutral100);
        expect(tint.iconBackground, DeelmarktColors.neutral100);
        expect(tint.iconForeground, DeelmarktColors.neutral500);
      });
    });

    group('dark mode', () {
      const brightness = Brightness.dark;

      test('returns non-null record for every known category', () {
        for (final id in allCategoryIds) {
          final tint = categoryTintFor(id, brightness);
          expect(tint.background, isNotNull, reason: '$id background');
          expect(tint.iconBackground, isNotNull, reason: '$id iconBackground');
          expect(tint.iconForeground, isNotNull, reason: '$id iconForeground');
        }
      });

      test('cat-electronics uses dark secondary', () {
        final tint = categoryTintFor('cat-electronics', brightness);
        expect(tint.background, DeelmarktColors.darkInfoSurface.withAlpha(128));
        expect(tint.iconBackground, DeelmarktColors.secondary.withAlpha(51));
        expect(tint.iconForeground, DeelmarktColors.darkSecondary);
      });

      test('cat-clothing uses dark error', () {
        final tint = categoryTintFor('cat-clothing', brightness);
        expect(
          tint.background,
          DeelmarktColors.darkErrorSurface.withAlpha(128),
        );
        expect(tint.iconBackground, DeelmarktColors.error.withAlpha(51));
        expect(tint.iconForeground, DeelmarktColors.darkError);
      });

      test('cat-home uses dark success', () {
        final tint = categoryTintFor('cat-home', brightness);
        expect(
          tint.background,
          DeelmarktColors.darkSuccessSurface.withAlpha(128),
        );
        expect(tint.iconBackground, DeelmarktColors.success.withAlpha(51));
        expect(tint.iconForeground, DeelmarktColors.darkSuccess);
      });

      test('cat-sport uses dark primary', () {
        final tint = categoryTintFor('cat-sport', brightness);
        expect(
          tint.background,
          DeelmarktColors.darkWarningSurface.withAlpha(128),
        );
        expect(tint.iconBackground, DeelmarktColors.primary.withAlpha(51));
        expect(tint.iconForeground, DeelmarktColors.darkPrimary);
      });

      test('cat-vehicles uses dark info', () {
        final tint = categoryTintFor('cat-vehicles', brightness);
        expect(tint.background, DeelmarktColors.darkInfoSurface.withAlpha(128));
        expect(tint.iconBackground, DeelmarktColors.info.withAlpha(51));
        expect(tint.iconForeground, DeelmarktColors.darkInfo);
      });

      test('cat-kids uses dark accent purple', () {
        final tint = categoryTintFor('cat-kids', brightness);
        expect(tint.background, DeelmarktColors.accentPurple.withAlpha(26));
        expect(tint.iconBackground, DeelmarktColors.accentPurple.withAlpha(51));
        expect(tint.iconForeground, DeelmarktColors.accentPurple);
      });

      test('cat-services uses dark surface elevated', () {
        final tint = categoryTintFor('cat-services', brightness);
        expect(tint.background, DeelmarktColors.darkSurfaceElevated);
        expect(tint.iconBackground, DeelmarktColors.neutral700.withAlpha(51));
        expect(tint.iconForeground, DeelmarktColors.darkOnSurfaceSecondary);
      });

      test('cat-other uses dark surface elevated', () {
        final tint = categoryTintFor('cat-other', brightness);
        expect(tint.background, DeelmarktColors.darkSurfaceElevated);
        expect(tint.iconBackground, DeelmarktColors.neutral700.withAlpha(51));
        expect(tint.iconForeground, DeelmarktColors.darkOnSurfaceSecondary);
      });

      test('unknown category returns dark fallback', () {
        final tint = categoryTintFor('cat-unknown', brightness);
        expect(tint.background, DeelmarktColors.darkSurfaceElevated);
        expect(tint.iconBackground, DeelmarktColors.neutral700.withAlpha(51));
        expect(tint.iconForeground, DeelmarktColors.darkOnSurfaceSecondary);
      });
    });

    group('edge cases', () {
      test('empty string returns fallback', () {
        final light = categoryTintFor('', Brightness.light);
        expect(light.iconForeground, DeelmarktColors.neutral500);

        final dark = categoryTintFor('', Brightness.dark);
        expect(dark.iconForeground, DeelmarktColors.darkOnSurfaceSecondary);
      });

      test('each category produces distinct colours in light mode', () {
        // Verify cat-electronics and cat-clothing return different tints
        final electronics = categoryTintFor(
          'cat-electronics',
          Brightness.light,
        );
        final clothing = categoryTintFor('cat-clothing', Brightness.light);
        expect(electronics.background, isNot(clothing.background));
        expect(electronics.iconForeground, isNot(clothing.iconForeground));
      });
    });
  });
}
