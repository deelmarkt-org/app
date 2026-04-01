import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';

/// Theme extension for badge-specific colours.
///
/// Separates verified/unverified/escrow badge colours from the general
/// trust theme so badge rendering stays self-contained.
///
/// Access: `Theme.of(context).extension<DeelBadgeThemeData>()!`
class DeelBadgeThemeData extends ThemeExtension<DeelBadgeThemeData> {
  const DeelBadgeThemeData({
    required this.verified,
    required this.escrow,
    required this.gold,
    required this.unverified,
    required this.verifiedBackground,
    required this.escrowBackground,
    required this.goldBackground,
    required this.unverifiedBackground,
    required this.tooltipBackground,
    required this.tooltipForeground,
  });

  factory DeelBadgeThemeData.light() => const DeelBadgeThemeData(
    verified: DeelmarktColors.trustVerified,
    escrow: DeelmarktColors.trustEscrow,
    gold: Color(0xFFD97706),
    unverified: DeelmarktColors.neutral500,
    verifiedBackground: Color(0xFFDCFCE7),
    escrowBackground: Color(0xFFDBEAFE),
    goldBackground: Color(0xFFFEF3C7),
    unverifiedBackground: DeelmarktColors.neutral100,
    tooltipBackground: DeelmarktColors.neutral900,
    tooltipForeground: DeelmarktColors.white,
  );

  factory DeelBadgeThemeData.dark() => const DeelBadgeThemeData(
    verified: DeelmarktColors.darkTrustVerified,
    escrow: DeelmarktColors.darkTrustEscrow,
    gold: Color(0xFFFBBF24),
    unverified: DeelmarktColors.darkOnSurfaceSecondary,
    verifiedBackground: Color(0xFF052E16),
    escrowBackground: Color(0xFF172554),
    goldBackground: Color(0xFF422006),
    unverifiedBackground: DeelmarktColors.darkSurfaceElevated,
    tooltipBackground: DeelmarktColors.darkSurfaceElevated,
    tooltipForeground: DeelmarktColors.darkOnSurface,
  );

  final Color verified;
  final Color escrow;
  final Color gold;
  final Color unverified;
  final Color verifiedBackground;
  final Color escrowBackground;
  final Color goldBackground;
  final Color unverifiedBackground;
  final Color tooltipBackground;
  final Color tooltipForeground;

  @override
  DeelBadgeThemeData copyWith({
    Color? verified,
    Color? escrow,
    Color? gold,
    Color? unverified,
    Color? verifiedBackground,
    Color? escrowBackground,
    Color? goldBackground,
    Color? unverifiedBackground,
    Color? tooltipBackground,
    Color? tooltipForeground,
  }) {
    return DeelBadgeThemeData(
      verified: verified ?? this.verified,
      escrow: escrow ?? this.escrow,
      gold: gold ?? this.gold,
      unverified: unverified ?? this.unverified,
      verifiedBackground: verifiedBackground ?? this.verifiedBackground,
      escrowBackground: escrowBackground ?? this.escrowBackground,
      goldBackground: goldBackground ?? this.goldBackground,
      unverifiedBackground: unverifiedBackground ?? this.unverifiedBackground,
      tooltipBackground: tooltipBackground ?? this.tooltipBackground,
      tooltipForeground: tooltipForeground ?? this.tooltipForeground,
    );
  }

  @override
  DeelBadgeThemeData lerp(DeelBadgeThemeData? other, double t) {
    if (other is! DeelBadgeThemeData) return this;
    return DeelBadgeThemeData(
      verified: Color.lerp(verified, other.verified, t)!,
      escrow: Color.lerp(escrow, other.escrow, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      unverified: Color.lerp(unverified, other.unverified, t)!,
      verifiedBackground:
          Color.lerp(verifiedBackground, other.verifiedBackground, t)!,
      escrowBackground:
          Color.lerp(escrowBackground, other.escrowBackground, t)!,
      goldBackground: Color.lerp(goldBackground, other.goldBackground, t)!,
      unverifiedBackground:
          Color.lerp(unverifiedBackground, other.unverifiedBackground, t)!,
      tooltipBackground:
          Color.lerp(tooltipBackground, other.tooltipBackground, t)!,
      tooltipForeground:
          Color.lerp(tooltipForeground, other.tooltipForeground, t)!,
    );
  }
}
