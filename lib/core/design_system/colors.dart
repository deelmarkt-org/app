import 'package:flutter/material.dart';

/// DeelMarkt colour tokens.
/// Reference: docs/design-system/tokens.md
class DeelmarktColors {
  DeelmarktColors._();

  // Primary
  static const primary = Color(0xFFF15A24);
  static const primaryLight = Color(0xFFFF8A5C);
  static const primarySurface = Color(0xFFFFF3EE);
  static const secondary = Color(0xFF1E4F7A);
  static const secondaryLight = Color(0xFF2D6FA3);
  static const secondarySurface = Color(0xFFEAF5FF);

  // Semantic
  static const success = Color(0xFF2EAD4A);
  static const successSurface = Color(0xFFE8F8EC);
  static const warning = Color(0xFFFFC857);
  static const warningSurface = Color(0xFFFFF8E6);
  static const error = Color(0xFFE53E3E);
  static const errorSurface = Color(0xFFFDE8E8);
  static const info = Color(0xFF3B82F6);
  static const infoSurface = Color(0xFFEFF6FF);

  // Neutral
  static const neutral900 = Color(0xFF1A1A1A);
  static const neutral700 = Color(0xFF555555);
  static const neutral500 = Color(0xFF8A8A8A);
  static const neutral300 = Color(0xFFD1D5DB);
  static const neutral200 = Color(0xFFE5E5E5);
  static const neutral100 = Color(0xFFF3F4F6);
  static const neutral50 = Color(0xFFF8F9FB);
  static const white = Color(0xFFFFFFFF);

  // Trust (dedicated — never for general UI)
  static const trustVerified = Color(0xFF16A34A);
  static const trustEscrow = Color(0xFF2563EB);
  static const trustWarning = Color(0xFFDC2626);
  static const trustPending = Color(0xFFF59E0B);
  static const trustShield = Color(0xFFF0FDF4);

  // Dark mode overrides (tokens.md §Dark Mode)
  static const darkScaffold = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkSurfaceElevated = Color(0xFF2C2C2C);
  static const darkPrimary = Color(0xFFFF7A4D);
  static const darkSecondary = Color(0xFF5BA3D9);
  static const darkOnPrimary = Color(0xFF1A1A1A);
  static const darkOnSurface = Color(0xFFF2F2F2);
  static const darkOnSurfaceSecondary = Color(0xFFA0A0A0);
  static const darkBorder = Color(0xFF333333);
  static const darkDivider = Color(0xFF2C2C2C);

  /// Shimmer highlight in dark mode (tokens.md §Dark Mode).
  static const darkShimmerHighlight = Color(0xFF3C3C3C);

  static const darkSuccess = Color(0xFF4ADE80);
  static const darkWarning = Color(0xFFFBBF24);
  static const darkError = Color(0xFFF87171);
  static const darkInfo = Color(0xFF60A5FA);

  // Dark mode surfaces
  static const darkTrustShield = Color(0xFF052E16);
  static const darkSuccessSurface = Color(0xFF052E16);
  static const darkErrorSurface = Color(0xFF450A0A);
  static const darkWarningSurface = Color(0xFF422006);
  static const darkInfoSurface = Color(0xFF172554);

  // Dark mode trust (dedicated — never for general UI)
  static const darkTrustVerified = Color(0xFF4ADE80);
  static const darkTrustEscrow = Color(0xFF60A5FA);
  static const darkTrustWarning = Color(0xFFF87171);
  static const darkTrustPending = Color(0xFFFBBF24);
}
