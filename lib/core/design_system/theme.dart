import 'package:flutter/material.dart';

import 'colors.dart';
import 'radius.dart';
import 'spacing.dart';
import 'typography.dart';

/// DeelMarkt app theme (Material 3).
/// Reference: docs/design-system/tokens.md
class DeelmarktTheme {
  DeelmarktTheme._();

  // ── Light Theme ──────────────────────────────────────────────────────

  static ThemeData light = ThemeData(
    useMaterial3: true,
    fontFamily: DeelmarktTypography.fontFamily,
    textTheme: DeelmarktTypography.textTheme,
    primaryColor: DeelmarktColors.primary,
    scaffoldBackgroundColor: DeelmarktColors.neutral50,
    dividerColor: DeelmarktColors.neutral200,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: DeelmarktColors.primary,
      onPrimary: DeelmarktColors.white,
      secondary: DeelmarktColors.secondary,
      onSecondary: DeelmarktColors.white,
      error: DeelmarktColors.error,
      onError: DeelmarktColors.white,
      surface: DeelmarktColors.white,
      onSurface: DeelmarktColors.neutral900,
      surfaceContainerLowest: DeelmarktColors.white,
      surfaceContainerLow: DeelmarktColors.neutral50,
      surfaceContainer: DeelmarktColors.neutral100,
      outline: DeelmarktColors.neutral300,
      outlineVariant: DeelmarktColors.neutral200,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: DeelmarktColors.white,
      foregroundColor: DeelmarktColors.neutral900,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
        side: const BorderSide(color: DeelmarktColors.neutral200),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DeelmarktColors.primary,
        foregroundColor: DeelmarktColors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
        ),
        textStyle: DeelmarktTypography.textTheme.labelLarge?.copyWith(
          fontFamily: DeelmarktTypography.fontFamily,
          fontSize: 16,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DeelmarktColors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Spacing.s4,
        vertical: Spacing.s3,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DeelmarktRadius.md),
        borderSide: const BorderSide(color: DeelmarktColors.neutral200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DeelmarktRadius.md),
        borderSide: const BorderSide(color: DeelmarktColors.neutral200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DeelmarktRadius.md),
        borderSide: const BorderSide(color: DeelmarktColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DeelmarktRadius.md),
        borderSide: const BorderSide(color: DeelmarktColors.error),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: DeelmarktColors.white,
      indicatorColor: DeelmarktColors.primarySurface,
      labelTextStyle: WidgetStatePropertyAll(
        DeelmarktTypography.textTheme.bodySmall,
      ),
    ),
  );

  // ── Dark Theme ───────────────────────────────────────────────────────

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    fontFamily: DeelmarktTypography.fontFamily,
    textTheme: DeelmarktTypography.textTheme,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: DeelmarktColors.darkScaffold,
    dividerColor: DeelmarktColors.darkDivider,
    colorScheme: const ColorScheme.dark(
      primary: DeelmarktColors.darkPrimary,
      onPrimary: DeelmarktColors.darkOnPrimary,
      secondary: DeelmarktColors.darkSecondary,
      onSecondary: DeelmarktColors.darkOnPrimary,
      surface: DeelmarktColors.darkSurface,
      onSurface: DeelmarktColors.darkOnSurface,
      error: DeelmarktColors.darkError,
      onError: DeelmarktColors.darkOnPrimary,
      surfaceContainerLowest: DeelmarktColors.darkScaffold,
      surfaceContainerLow: DeelmarktColors.darkSurface,
      surfaceContainer: DeelmarktColors.darkSurfaceElevated,
      outline: DeelmarktColors.darkBorder,
      outlineVariant: DeelmarktColors.darkDivider,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: DeelmarktColors.darkSurface,
      foregroundColor: DeelmarktColors.darkOnSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
        side: const BorderSide(color: DeelmarktColors.darkBorder),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DeelmarktColors.darkPrimary,
        foregroundColor: DeelmarktColors.darkOnPrimary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
        ),
        textStyle: DeelmarktTypography.textTheme.labelLarge?.copyWith(
          fontFamily: DeelmarktTypography.fontFamily,
          fontSize: 16,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DeelmarktColors.darkSurface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Spacing.s4,
        vertical: Spacing.s3,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DeelmarktRadius.md),
        borderSide: const BorderSide(color: DeelmarktColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DeelmarktRadius.md),
        borderSide: const BorderSide(color: DeelmarktColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DeelmarktRadius.md),
        borderSide: const BorderSide(
          color: DeelmarktColors.darkPrimary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DeelmarktRadius.md),
        borderSide: const BorderSide(color: DeelmarktColors.darkError),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: DeelmarktColors.darkSurface,
      indicatorColor: DeelmarktColors.darkSurfaceElevated,
      labelTextStyle: WidgetStatePropertyAll(
        DeelmarktTypography.textTheme.bodySmall,
      ),
    ),
  );
}
