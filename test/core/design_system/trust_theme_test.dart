import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/trust_theme.dart';

void main() {
  group('DeelmarktTrustTheme', () {
    group('light() factory', () {
      test('sets light trust color tokens', () {
        final theme = DeelmarktTrustTheme.light();
        expect(theme.verified, DeelmarktColors.trustVerified);
        expect(theme.escrow, DeelmarktColors.trustEscrow);
        expect(theme.warning, DeelmarktColors.trustWarning);
        expect(theme.pending, DeelmarktColors.trustPending);
        expect(theme.shield, DeelmarktColors.trustShield);
      });

      test('sets light scam-alert color tokens', () {
        final theme = DeelmarktTrustTheme.light();
        expect(theme.scamHighSurface, DeelmarktColors.errorSurface);
        expect(theme.scamHighAccent, DeelmarktColors.error);
        expect(theme.scamLowSurface, DeelmarktColors.warningSurface);
        expect(theme.scamLowAccent, DeelmarktColors.warning);
      });
    });

    group('dark() factory', () {
      test('sets dark trust color tokens', () {
        final theme = DeelmarktTrustTheme.dark();
        expect(theme.verified, DeelmarktColors.darkTrustVerified);
        expect(theme.escrow, DeelmarktColors.darkTrustEscrow);
        expect(theme.warning, DeelmarktColors.darkTrustWarning);
        expect(theme.pending, DeelmarktColors.darkTrustPending);
        expect(theme.shield, DeelmarktColors.darkTrustShield);
      });

      test('sets dark scam-alert color tokens', () {
        final theme = DeelmarktTrustTheme.dark();
        expect(theme.scamHighSurface, DeelmarktColors.darkErrorSurface);
        expect(theme.scamHighAccent, DeelmarktColors.darkError);
        expect(theme.scamLowSurface, DeelmarktColors.darkWarningSurface);
        expect(theme.scamLowAccent, DeelmarktColors.darkWarning);
      });
    });

    group('copyWith', () {
      test('overrides a single color field', () {
        final original = DeelmarktTrustTheme.light();
        const overrideColor = Color(0xFFDEADBE);
        final copy = original.copyWith(verified: overrideColor);
        expect(copy.verified, overrideColor);
        expect(copy.escrow, original.escrow);
      });

      test('preserves all fields when no arguments given', () {
        final original = DeelmarktTrustTheme.light();
        final copy = original.copyWith();
        expect(copy.verified, original.verified);
        expect(copy.escrow, original.escrow);
        expect(copy.warning, original.warning);
        expect(copy.pending, original.pending);
        expect(copy.shield, original.shield);
        expect(copy.scamHighSurface, original.scamHighSurface);
        expect(copy.scamHighAccent, original.scamHighAccent);
        expect(copy.scamLowSurface, original.scamLowSurface);
        expect(copy.scamLowAccent, original.scamLowAccent);
      });
    });

    group('lerp', () {
      test('at t=0 returns the original colors', () {
        final a = DeelmarktTrustTheme.light();
        final b = DeelmarktTrustTheme.dark();
        final result = a.lerp(b, 0.0);
        expect(result.verified, a.verified);
        expect(result.escrow, a.escrow);
        expect(result.scamHighAccent, a.scamHighAccent);
      });

      test('at t=1 returns the other colors', () {
        final a = DeelmarktTrustTheme.light();
        final b = DeelmarktTrustTheme.dark();
        final result = a.lerp(b, 1.0);
        expect(result.verified, b.verified);
        expect(result.escrow, b.escrow);
        expect(result.scamHighAccent, b.scamHighAccent);
      });

      test('with null returns this unchanged', () {
        final a = DeelmarktTrustTheme.light();
        final result = a.lerp(null, 0.5);
        expect(result.verified, a.verified);
      });
    });
  });
}
