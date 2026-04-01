import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';

/// Theme extension for trust-specific colours.
///
/// Eliminates manual `theme.brightness` switching in trust UI widgets
/// by integrating trust colour tokens into the theme system.
///
/// Access: `Theme.of(context).extension<DeelmarktTrustTheme>()!`
///
/// Reference: docs/design-system/tokens.md §Trust Colours
class DeelmarktTrustTheme extends ThemeExtension<DeelmarktTrustTheme> {
  const DeelmarktTrustTheme({
    required this.verified,
    required this.escrow,
    required this.warning,
    required this.pending,
    required this.shield,
  });

  factory DeelmarktTrustTheme.light() => const DeelmarktTrustTheme(
    verified: DeelmarktColors.trustVerified,
    escrow: DeelmarktColors.trustEscrow,
    warning: DeelmarktColors.trustWarning,
    pending: DeelmarktColors.trustPending,
    shield: DeelmarktColors.trustShield,
  );

  factory DeelmarktTrustTheme.dark() => const DeelmarktTrustTheme(
    verified: DeelmarktColors.darkTrustVerified,
    escrow: DeelmarktColors.darkTrustEscrow,
    warning: DeelmarktColors.darkTrustWarning,
    pending: DeelmarktColors.darkTrustPending,
    shield: DeelmarktColors.darkTrustShield,
  );

  final Color verified;
  final Color escrow;
  final Color warning;
  final Color pending;
  final Color shield;

  @override
  DeelmarktTrustTheme copyWith({
    Color? verified,
    Color? escrow,
    Color? warning,
    Color? pending,
    Color? shield,
  }) {
    return DeelmarktTrustTheme(
      verified: verified ?? this.verified,
      escrow: escrow ?? this.escrow,
      warning: warning ?? this.warning,
      pending: pending ?? this.pending,
      shield: shield ?? this.shield,
    );
  }

  @override
  DeelmarktTrustTheme lerp(DeelmarktTrustTheme? other, double t) {
    if (other is! DeelmarktTrustTheme) return this;
    return DeelmarktTrustTheme(
      verified: Color.lerp(verified, other.verified, t)!,
      escrow: Color.lerp(escrow, other.escrow, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      pending: Color.lerp(pending, other.pending, t)!,
      shield: Color.lerp(shield, other.shield, t)!,
    );
  }
}
