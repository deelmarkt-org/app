import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/design_system/typography.dart';
import 'package:deelmarkt/main.dart';

void main() {
  group('DeelmarktColors', () {
    test('primary orange matches brand hex #F15A24', () {
      expect(DeelmarktColors.primary, const Color(0xFFF15A24));
    });

    test('secondary blue matches brand hex #1E4F7A', () {
      expect(DeelmarktColors.secondary, const Color(0xFF1E4F7A));
    });

    test('trust colours are distinct from semantic colours', () {
      expect(DeelmarktColors.trustVerified, isNot(DeelmarktColors.success));
      expect(DeelmarktColors.trustWarning, isNot(DeelmarktColors.error));
    });
  });

  group('DeelmarktColors dark mode', () {
    test('dark primary is lighter orange #FF7A4D', () {
      expect(DeelmarktColors.darkPrimary, const Color(0xFFFF7A4D));
    });

    test('dark secondary is lighter blue #5BA3D9', () {
      expect(DeelmarktColors.darkSecondary, const Color(0xFF5BA3D9));
    });

    test('dark scaffold is #121212', () {
      expect(DeelmarktColors.darkScaffold, const Color(0xFF121212));
    });

    test('dark surface is #1E1E1E', () {
      expect(DeelmarktColors.darkSurface, const Color(0xFF1E1E1E));
    });

    test('dark error is #F87171', () {
      expect(DeelmarktColors.darkError, const Color(0xFFF87171));
    });
  });

  group('Spacing', () {
    test('base unit is 4px', () {
      expect(Spacing.s1, 4);
    });

    test('all spacing values are multiples of 4', () {
      final values = [
        Spacing.s1,
        Spacing.s2,
        Spacing.s3,
        Spacing.s4,
        Spacing.s5,
        Spacing.s6,
        Spacing.s8,
        Spacing.s10,
        Spacing.s12,
        Spacing.s16,
      ];
      for (final v in values) {
        expect(v % 4, 0, reason: '$v is not a multiple of 4');
      }
    });
  });

  group('DeelmarktRadius', () {
    test('card radius is xl (16px)', () {
      expect(DeelmarktRadius.xl, 16);
    });

    test('button radius is lg (12px)', () {
      expect(DeelmarktRadius.lg, 12);
    });

    test('input radius is md (10px)', () {
      expect(DeelmarktRadius.md, 10);
    });
  });

  group('DeelmarktTypography', () {
    test('price style has tabular figures', () {
      expect(
        DeelmarktTypography.price.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });

    test('priceSm style has tabular figures', () {
      expect(
        DeelmarktTypography.priceSm.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });
  });

  group('DeelmarktTheme light', () {
    test('uses Material 3', () {
      expect(DeelmarktTheme.light.useMaterial3, true);
    });

    test('scaffold is neutral-50', () {
      expect(
        DeelmarktTheme.light.scaffoldBackgroundColor,
        DeelmarktColors.neutral50,
      );
    });

    test('primary is DeelMarkt orange', () {
      expect(DeelmarktTheme.light.colorScheme.primary, DeelmarktColors.primary);
    });

    test('appBar uses DeelmarktColors.white', () {
      expect(
        DeelmarktTheme.light.appBarTheme.backgroundColor,
        DeelmarktColors.white,
      );
    });

    test('input padding uses Spacing tokens', () {
      final padding =
          DeelmarktTheme.light.inputDecorationTheme.contentPadding
              as EdgeInsets;
      expect(padding.left, Spacing.s4);
      expect(padding.top, Spacing.s3);
    });
  });

  group('DeelmarktTheme dark', () {
    test('uses Material 3', () {
      expect(DeelmarktTheme.dark.useMaterial3, true);
    });

    test('scaffold uses darkScaffold colour', () {
      expect(
        DeelmarktTheme.dark.scaffoldBackgroundColor,
        DeelmarktColors.darkScaffold,
      );
    });

    test('primary is darkPrimary #FF7A4D', () {
      expect(
        DeelmarktTheme.dark.colorScheme.primary,
        DeelmarktColors.darkPrimary,
      );
    });

    test('appBar uses darkSurface', () {
      expect(
        DeelmarktTheme.dark.appBarTheme.backgroundColor,
        DeelmarktColors.darkSurface,
      );
    });

    test('card uses darkBorder stroke', () {
      final shape =
          DeelmarktTheme.dark.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.side.color, DeelmarktColors.darkBorder);
    });

    test('has elevatedButtonTheme', () {
      expect(DeelmarktTheme.dark.elevatedButtonTheme.style, isNotNull);
    });

    test('has inputDecorationTheme', () {
      expect(
        DeelmarktTheme.dark.inputDecorationTheme.fillColor,
        DeelmarktColors.darkSurface,
      );
    });
  });

  group('DeelMarktApp', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: DeelMarktApp()));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsWidgets);
    });
  });
}
