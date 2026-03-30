import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';

/// Theme extension providing per-variant colour tokens for [DeelButton].
///
/// Registered in [DeelmarktTheme.light] and [DeelmarktTheme.dark].
/// Access: `Theme.of(context).extension<DeelButtonThemeData>()`
///
/// Reference: docs/design-system/components.md §Buttons
@immutable
class DeelButtonThemeData extends ThemeExtension<DeelButtonThemeData> {
  const DeelButtonThemeData({
    required this.primaryBackground,
    required this.primaryForeground,
    required this.secondaryBackground,
    required this.secondaryForeground,
    required this.outlineBorderColor,
    required this.outlineForeground,
    required this.ghostForeground,
    required this.destructiveBackground,
    required this.destructiveForeground,
    required this.successBackground,
    required this.successForeground,
  });

  final Color primaryBackground;
  final Color primaryForeground;
  final Color secondaryBackground;
  final Color secondaryForeground;
  final Color outlineBorderColor;
  final Color outlineForeground;
  final Color ghostForeground;
  final Color destructiveBackground;
  final Color destructiveForeground;
  final Color successBackground;
  final Color successForeground;

  /// Light theme variant colours.
  factory DeelButtonThemeData.light() {
    return const DeelButtonThemeData(
      primaryBackground: DeelmarktColors.primary,
      primaryForeground: DeelmarktColors.white,
      secondaryBackground: DeelmarktColors.secondary,
      secondaryForeground: DeelmarktColors.white,
      outlineBorderColor: DeelmarktColors.secondary,
      outlineForeground: DeelmarktColors.secondary,
      ghostForeground: DeelmarktColors.neutral700,
      destructiveBackground: DeelmarktColors.error,
      destructiveForeground: DeelmarktColors.white,
      successBackground: DeelmarktColors.success,
      successForeground: DeelmarktColors.white,
    );
  }

  /// Dark theme variant colours.
  factory DeelButtonThemeData.dark() {
    return const DeelButtonThemeData(
      primaryBackground: DeelmarktColors.darkPrimary,
      primaryForeground: DeelmarktColors.darkOnPrimary,
      secondaryBackground: DeelmarktColors.darkSecondary,
      secondaryForeground: DeelmarktColors.darkOnPrimary,
      outlineBorderColor: DeelmarktColors.darkSecondary,
      outlineForeground: DeelmarktColors.darkSecondary,
      ghostForeground: DeelmarktColors.darkOnSurfaceSecondary,
      destructiveBackground: DeelmarktColors.darkError,
      destructiveForeground: DeelmarktColors.darkOnPrimary,
      successBackground: DeelmarktColors.darkSuccess,
      successForeground: DeelmarktColors.darkOnPrimary,
    );
  }

  @override
  DeelButtonThemeData copyWith({
    Color? primaryBackground,
    Color? primaryForeground,
    Color? secondaryBackground,
    Color? secondaryForeground,
    Color? outlineBorderColor,
    Color? outlineForeground,
    Color? ghostForeground,
    Color? destructiveBackground,
    Color? destructiveForeground,
    Color? successBackground,
    Color? successForeground,
  }) {
    return DeelButtonThemeData(
      primaryBackground: primaryBackground ?? this.primaryBackground,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      secondaryBackground: secondaryBackground ?? this.secondaryBackground,
      secondaryForeground: secondaryForeground ?? this.secondaryForeground,
      outlineBorderColor: outlineBorderColor ?? this.outlineBorderColor,
      outlineForeground: outlineForeground ?? this.outlineForeground,
      ghostForeground: ghostForeground ?? this.ghostForeground,
      destructiveBackground:
          destructiveBackground ?? this.destructiveBackground,
      destructiveForeground:
          destructiveForeground ?? this.destructiveForeground,
      successBackground: successBackground ?? this.successBackground,
      successForeground: successForeground ?? this.successForeground,
    );
  }

  @override
  DeelButtonThemeData lerp(covariant DeelButtonThemeData? other, double t) {
    if (other == null) return this;
    return DeelButtonThemeData(
      primaryBackground:
          Color.lerp(primaryBackground, other.primaryBackground, t)!,
      primaryForeground:
          Color.lerp(primaryForeground, other.primaryForeground, t)!,
      secondaryBackground:
          Color.lerp(secondaryBackground, other.secondaryBackground, t)!,
      secondaryForeground:
          Color.lerp(secondaryForeground, other.secondaryForeground, t)!,
      outlineBorderColor:
          Color.lerp(outlineBorderColor, other.outlineBorderColor, t)!,
      outlineForeground:
          Color.lerp(outlineForeground, other.outlineForeground, t)!,
      ghostForeground: Color.lerp(ghostForeground, other.ghostForeground, t)!,
      destructiveBackground:
          Color.lerp(destructiveBackground, other.destructiveBackground, t)!,
      destructiveForeground:
          Color.lerp(destructiveForeground, other.destructiveForeground, t)!,
      successBackground:
          Color.lerp(successBackground, other.successBackground, t)!,
      successForeground:
          Color.lerp(successForeground, other.successForeground, t)!,
    );
  }
}
