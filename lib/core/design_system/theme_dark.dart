import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/deel_badge_theme.dart';
import 'package:deelmarkt/core/design_system/deel_button_theme.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/design_system/trust_theme.dart';
import 'package:deelmarkt/core/design_system/typography.dart';

/// Dark theme for DeelMarkt (Material 3).
///
/// Consume via `DeelmarktTheme.dark` — do not call this builder directly.
///
/// Reference: docs/design-system/tokens.md §Dark Mode
ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: DeelmarktTypography.fontFamily,
    extensions: <ThemeExtension>[
      DeelBadgeThemeData.dark(),
      DeelButtonThemeData.dark(),
      DeelmarktTrustTheme.dark(),
    ],
    textTheme: DeelmarktTypography.textTheme,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: DeelmarktColors.darkScaffold,
    dividerTheme: const DividerThemeData(color: DeelmarktColors.darkDivider),
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
      onSurfaceVariant: DeelmarktColors.darkOnSurfaceSecondary,
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
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DeelmarktRadius.md),
        borderSide: const BorderSide(
          color: DeelmarktColors.darkError,
          width: 2,
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: DeelmarktColors.darkSurface,
      indicatorColor: DeelmarktColors.darkSurfaceElevated,
      labelTextStyle: WidgetStatePropertyAll(
        DeelmarktTypography.textTheme.bodySmall,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DeelmarktColors.darkPrimary;
          }
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DeelmarktColors.darkOnPrimary;
          }
          return DeelmarktColors.darkOnSurfaceSecondary;
        }),
        minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
          ),
        ),
        side: const WidgetStatePropertyAll(
          BorderSide(color: DeelmarktColors.darkBorder),
        ),
      ),
    ),
  );
}
