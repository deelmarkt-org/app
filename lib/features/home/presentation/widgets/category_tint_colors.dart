import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';

/// Tint colour set for category cards and detail screens.
///
/// Returns background, icon background, and icon foreground colours
/// mapped to each L1 category ID, using design system tokens.
({Color background, Color iconBackground, Color iconForeground})
categoryTintFor(String categoryId, Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  return switch (categoryId) {
    'cat-electronics' => (
      background:
          isDark
              ? DeelmarktColors.darkInfoSurface.withAlpha(128)
              : DeelmarktColors.secondarySurface,
      iconBackground:
          isDark
              ? DeelmarktColors.secondary.withAlpha(51)
              : DeelmarktColors.secondarySurface,
      iconForeground:
          isDark ? DeelmarktColors.darkSecondary : DeelmarktColors.secondary,
    ),
    'cat-clothing' => (
      background:
          isDark
              ? DeelmarktColors.darkErrorSurface.withAlpha(128)
              : DeelmarktColors.errorSurface,
      iconBackground:
          isDark
              ? DeelmarktColors.error.withAlpha(51)
              : DeelmarktColors.errorSurface,
      iconForeground:
          isDark ? DeelmarktColors.darkError : DeelmarktColors.error,
    ),
    'cat-home' => (
      background:
          isDark
              ? DeelmarktColors.darkSuccessSurface.withAlpha(128)
              : DeelmarktColors.successSurface,
      iconBackground:
          isDark
              ? DeelmarktColors.success.withAlpha(51)
              : DeelmarktColors.successSurface,
      iconForeground:
          isDark ? DeelmarktColors.darkSuccess : DeelmarktColors.success,
    ),
    'cat-sport' => (
      background:
          isDark
              ? DeelmarktColors.darkWarningSurface.withAlpha(128)
              : DeelmarktColors.primarySurface,
      iconBackground:
          isDark
              ? DeelmarktColors.primary.withAlpha(51)
              : DeelmarktColors.primarySurface,
      iconForeground:
          isDark ? DeelmarktColors.darkPrimary : DeelmarktColors.primary,
    ),
    'cat-vehicles' => (
      background:
          isDark
              ? DeelmarktColors.darkInfoSurface.withAlpha(128)
              : DeelmarktColors.infoSurface,
      iconBackground:
          isDark
              ? DeelmarktColors.info.withAlpha(51)
              : DeelmarktColors.infoSurface,
      iconForeground: isDark ? DeelmarktColors.darkInfo : DeelmarktColors.info,
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
    'cat-services' => (
      background:
          isDark
              ? DeelmarktColors.darkSurfaceElevated
              : DeelmarktColors.neutral100,
      iconBackground:
          isDark
              ? DeelmarktColors.neutral700.withAlpha(51)
              : DeelmarktColors.neutral100,
      iconForeground:
          isDark
              ? DeelmarktColors.darkOnSurfaceSecondary
              : DeelmarktColors.neutral700,
    ),
    'cat-other' => (
      background:
          isDark
              ? DeelmarktColors.darkSurfaceElevated
              : DeelmarktColors.neutral100,
      iconBackground:
          isDark
              ? DeelmarktColors.neutral700.withAlpha(51)
              : DeelmarktColors.neutral100,
      iconForeground:
          isDark
              ? DeelmarktColors.darkOnSurfaceSecondary
              : DeelmarktColors.neutral700,
    ),
    // Fallback for unknown category IDs
    _ => (
      background:
          isDark
              ? DeelmarktColors.darkSurfaceElevated
              : DeelmarktColors.neutral100,
      iconBackground:
          isDark
              ? DeelmarktColors.neutral700.withAlpha(51)
              : DeelmarktColors.neutral100,
      iconForeground:
          isDark
              ? DeelmarktColors.darkOnSurfaceSecondary
              : DeelmarktColors.neutral500,
    ),
  };
}
