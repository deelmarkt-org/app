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

/// Tint colour set for category cards and detail screens.
///
/// Returns background, icon background, and icon foreground colours
/// mapped to each L1 category ID, using design system tokens.
CategoryTint categoryTintFor(String categoryId, Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  return switch (categoryId) {
    'cat-electronics' => _tint(
      lightSurface: DeelmarktColors.secondarySurface,
      darkSurface: DeelmarktColors.darkInfoSurface,
      accent: DeelmarktColors.secondary,
      lightForeground: DeelmarktColors.secondary,
      darkForeground: DeelmarktColors.darkSecondary,
      isDark: isDark,
    ),
    'cat-clothing' => _tint(
      lightSurface: DeelmarktColors.errorSurface,
      darkSurface: DeelmarktColors.darkErrorSurface,
      accent: DeelmarktColors.error,
      lightForeground: DeelmarktColors.error,
      darkForeground: DeelmarktColors.darkError,
      isDark: isDark,
    ),
    'cat-home' => _tint(
      lightSurface: DeelmarktColors.successSurface,
      darkSurface: DeelmarktColors.darkSuccessSurface,
      accent: DeelmarktColors.success,
      lightForeground: DeelmarktColors.success,
      darkForeground: DeelmarktColors.darkSuccess,
      isDark: isDark,
    ),
    'cat-sport' => _tint(
      lightSurface: DeelmarktColors.primarySurface,
      darkSurface: DeelmarktColors.darkWarningSurface,
      accent: DeelmarktColors.primary,
      lightForeground: DeelmarktColors.primary,
      darkForeground: DeelmarktColors.darkPrimary,
      isDark: isDark,
    ),
    'cat-vehicles' => _tint(
      lightSurface: DeelmarktColors.infoSurface,
      darkSurface: DeelmarktColors.darkInfoSurface,
      accent: DeelmarktColors.info,
      lightForeground: DeelmarktColors.info,
      darkForeground: DeelmarktColors.darkInfo,
      isDark: isDark,
    ),
    'cat-kids' => (
      background:
          isDark
              ? DeelmarktColors.accentPurple.withAlpha(26)
              : DeelmarktColors.accentPurpleSurface,
      iconBackground:
          isDark
              ? DeelmarktColors.accentPurple.withAlpha(51)
              : DeelmarktColors.accentPurpleSurface,
      iconForeground: DeelmarktColors.accentPurple,
    ),
    'cat-services' => _neutralTint(
      isDark: isDark,
      darkForeground: DeelmarktColors.darkOnSurfaceSecondary,
      lightForeground: DeelmarktColors.neutral700,
    ),
    'cat-other' => _neutralTint(
      isDark: isDark,
      darkForeground: DeelmarktColors.darkOnSurfaceSecondary,
      lightForeground: DeelmarktColors.neutral700,
    ),
    _ => _neutralTint(
      isDark: isDark,
      darkForeground: DeelmarktColors.darkOnSurfaceSecondary,
      lightForeground: DeelmarktColors.neutral500,
    ),
  };
}
