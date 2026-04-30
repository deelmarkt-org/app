/// Smoke tests for `buildDarkTheme()` — extracted from `theme.dart`
/// to keep both files under the §2.1 200-LOC budget. Verifies the
/// theme builds without throwing and that the load-bearing brand
/// tokens are present (so a colour-token rename surfaces here, not
/// when the dark surface ships looking wrong).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/deel_badge_theme.dart';
import 'package:deelmarkt/core/design_system/deel_button_theme.dart';
import 'package:deelmarkt/core/design_system/theme_dark.dart';
import 'package:deelmarkt/core/design_system/trust_theme.dart';

void main() {
  group('buildDarkTheme', () {
    test('builds a Material 3 dark theme without throwing', () {
      final theme = buildDarkTheme();
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
    });

    test('wires the three feature theme extensions', () {
      final theme = buildDarkTheme();
      expect(theme.extension<DeelBadgeThemeData>(), isNotNull);
      expect(theme.extension<DeelButtonThemeData>(), isNotNull);
      expect(theme.extension<DeelmarktTrustTheme>(), isNotNull);
    });

    test('uses the dark colour palette for primary, surface, scaffold', () {
      final theme = buildDarkTheme();
      expect(theme.colorScheme.primary, DeelmarktColors.darkPrimary);
      expect(theme.colorScheme.surface, DeelmarktColors.darkSurface);
      expect(theme.scaffoldBackgroundColor, DeelmarktColors.darkScaffold);
    });

    test('segmented + elevated button sizes meet 44 px WCAG minimum', () {
      final theme = buildDarkTheme();
      // Segmented button minimumSize height ≥ 44.
      final segmentedSize = theme.segmentedButtonTheme.style!.minimumSize!
          .resolve({});
      expect(segmentedSize!.height, greaterThanOrEqualTo(44));
      // Elevated button minimumSize height = 52 (per components.md large).
      final elevatedSize = theme.elevatedButtonTheme.style!.minimumSize!
          .resolve({});
      expect(elevatedSize!.height, 52);
    });
  });
}
