import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';

/// Record type for category tint colour sets.
typedef CategoryTint =
    ({Color background, Color iconBackground, Color iconForeground});

/// Builds a tint record from a light surface colour and a dark accent colour.
///
/// Used by most categories that follow the standard light/dark pattern:
/// - Light mode: surface colour for background + icon background
/// - Dark mode: accent with low alpha for background, medium alpha for icon
CategoryTint _tint({
  required Color lightSurface,
  required Color darkSurface,
  required Color accent,
  required Color lightForeground,
  required Color darkForeground,
  required bool isDark,
}) => (
  background: isDark ? darkSurface.withAlpha(128) : lightSurface,
  iconBackground: isDark ? accent.withAlpha(51) : lightSurface,
  iconForeground: isDark ? darkForeground : lightForeground,
);

/// Neutral tint used for services, other, and unknown categories.
CategoryTint _neutralTint({
  required bool isDark,
  required Color darkForeground,
  required Color lightForeground,
}) => (
  background:
      isDark ? DeelmarktColors.darkSurfaceElevated : DeelmarktColors.neutral100,
  iconBackground:
      isDark
          ? DeelmarktColors.neutral700.withAlpha(51)
          : DeelmarktColors.neutral100,
  iconForeground: isDark ? darkForeground : lightForeground,
);

/// Config for standard light/dark tint categories — feeds [_tint].
typedef _TintConfig =
    ({
      Color lightSurface,
      Color darkSurface,
      Color accent,
      Color lightForeground,
      Color darkForeground,
    });

const Map<String, _TintConfig> _standardTints = {
  'cat-electronics': (
    lightSurface: DeelmarktColors.secondarySurface,
    darkSurface: DeelmarktColors.darkInfoSurface,
    accent: DeelmarktColors.secondary,
    lightForeground: DeelmarktColors.secondary,
    darkForeground: DeelmarktColors.darkSecondary,
  ),
  'cat-clothing': (
    lightSurface: DeelmarktColors.errorSurface,
    darkSurface: DeelmarktColors.darkErrorSurface,
    accent: DeelmarktColors.error,
    lightForeground: DeelmarktColors.error,
    darkForeground: DeelmarktColors.darkError,
  ),
  'cat-home': (
    lightSurface: DeelmarktColors.successSurface,
    darkSurface: DeelmarktColors.darkSuccessSurface,
    accent: DeelmarktColors.success,
    lightForeground: DeelmarktColors.success,
    darkForeground: DeelmarktColors.darkSuccess,
  ),
  'cat-sport': (
    lightSurface: DeelmarktColors.primarySurface,
    darkSurface: DeelmarktColors.darkWarningSurface,
    accent: DeelmarktColors.primary,
    lightForeground: DeelmarktColors.primary,
    darkForeground: DeelmarktColors.darkPrimary,
  ),
  'cat-vehicles': (
    lightSurface: DeelmarktColors.infoSurface,
    darkSurface: DeelmarktColors.darkInfoSurface,
    accent: DeelmarktColors.info,
    lightForeground: DeelmarktColors.info,
    darkForeground: DeelmarktColors.darkInfo,
  ),
};

const _namedNeutralCategoryIds = {'cat-services', 'cat-other'};

CategoryTint _kidsTint(bool isDark) => (
  background:
      isDark
          ? DeelmarktColors.accentPurple.withAlpha(26)
          : DeelmarktColors.accentPurpleSurface,
  iconBackground:
      isDark
          ? DeelmarktColors.accentPurple.withAlpha(51)
          : DeelmarktColors.accentPurpleSurface,
  iconForeground: DeelmarktColors.accentPurple,
);

/// Tint colour set for category cards and detail screens.
///
/// Returns background, icon background, and icon foreground colours
/// mapped to each L1 category ID, using design system tokens.
CategoryTint categoryTintFor(String categoryId, Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final standard = _standardTints[categoryId];
  if (standard != null) {
    return _tint(
      lightSurface: standard.lightSurface,
      darkSurface: standard.darkSurface,
      accent: standard.accent,
      lightForeground: standard.lightForeground,
      darkForeground: standard.darkForeground,
      isDark: isDark,
    );
  }
  if (categoryId == 'cat-kids') return _kidsTint(isDark);

  return _neutralTint(
    isDark: isDark,
    darkForeground: DeelmarktColors.darkOnSurfaceSecondary,
    lightForeground:
        _namedNeutralCategoryIds.contains(categoryId)
            ? DeelmarktColors.neutral700
            : DeelmarktColors.neutral500,
  );
}
