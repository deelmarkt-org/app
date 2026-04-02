import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/deel_badge_theme.dart';

void main() {
  group('DeelBadgeThemeData', () {
    group('light()', () {
      test('creates theme with correct verified color', () {
        final theme = DeelBadgeThemeData.light();
        expect(theme.verified, equals(DeelmarktColors.trustVerified));
      });

      test('creates theme with correct escrow color', () {
        final theme = DeelBadgeThemeData.light();
        expect(theme.escrow, equals(DeelmarktColors.trustEscrow));
      });

      test('creates theme with correct unverified color', () {
        final theme = DeelBadgeThemeData.light();
        expect(theme.unverified, equals(DeelmarktColors.neutral500));
      });

      test('creates theme with correct tooltip colors', () {
        final theme = DeelBadgeThemeData.light();
        expect(theme.tooltipBackground, equals(DeelmarktColors.neutral900));
        expect(theme.tooltipForeground, equals(DeelmarktColors.white));
      });

      test('creates theme with correct gold color', () {
        final theme = DeelBadgeThemeData.light();
        expect(theme.gold, equals(const Color(0xFFD97706)));
      });

      test('creates theme with correct background colors', () {
        final theme = DeelBadgeThemeData.light();
        expect(theme.verifiedBackground, equals(const Color(0xFFDCFCE7)));
        expect(theme.escrowBackground, equals(const Color(0xFFDBEAFE)));
        expect(theme.goldBackground, equals(const Color(0xFFFEF3C7)));
        expect(theme.unverifiedBackground, equals(DeelmarktColors.neutral100));
      });
    });

    group('dark()', () {
      test('creates theme with correct verified color', () {
        final theme = DeelBadgeThemeData.dark();
        expect(theme.verified, equals(DeelmarktColors.darkTrustVerified));
      });

      test('creates theme with correct escrow color', () {
        final theme = DeelBadgeThemeData.dark();
        expect(theme.escrow, equals(DeelmarktColors.darkTrustEscrow));
      });

      test('creates theme with correct unverified color', () {
        final theme = DeelBadgeThemeData.dark();
        expect(
          theme.unverified,
          equals(DeelmarktColors.darkOnSurfaceSecondary),
        );
      });

      test('creates theme with correct tooltip colors', () {
        final theme = DeelBadgeThemeData.dark();
        expect(
          theme.tooltipBackground,
          equals(DeelmarktColors.darkSurfaceElevated),
        );
        expect(theme.tooltipForeground, equals(DeelmarktColors.darkOnSurface));
      });

      test('creates theme with correct gold color', () {
        final theme = DeelBadgeThemeData.dark();
        expect(theme.gold, equals(const Color(0xFFFBBF24)));
      });

      test('creates theme with correct dark background colors', () {
        final theme = DeelBadgeThemeData.dark();
        expect(theme.verifiedBackground, equals(const Color(0xFF052E16)));
        expect(theme.escrowBackground, equals(const Color(0xFF172554)));
        expect(theme.goldBackground, equals(const Color(0xFF422006)));
        expect(
          theme.unverifiedBackground,
          equals(DeelmarktColors.darkSurfaceElevated),
        );
      });
    });

    group('copyWith()', () {
      test('returns new instance with overridden verified color', () {
        final theme = DeelBadgeThemeData.light();
        final updated = theme.copyWith(verified: Colors.red);
        expect(updated.verified, equals(Colors.red));
        expect(updated.escrow, equals(theme.escrow));
      });

      test('preserves all other fields when one is changed', () {
        final theme = DeelBadgeThemeData.light();
        final updated = theme.copyWith(gold: Colors.amber);
        expect(updated.gold, equals(Colors.amber));
        expect(updated.verified, equals(theme.verified));
        expect(updated.escrow, equals(theme.escrow));
        expect(updated.unverified, equals(theme.unverified));
        expect(updated.verifiedBackground, equals(theme.verifiedBackground));
        expect(updated.tooltipBackground, equals(theme.tooltipBackground));
      });

      test('can override all fields', () {
        final theme = DeelBadgeThemeData.light();
        final updated = theme.copyWith(
          verified: Colors.red,
          escrow: Colors.blue,
          gold: Colors.amber,
          unverified: Colors.grey,
          verifiedBackground: Colors.green,
          escrowBackground: Colors.lightBlue,
          goldBackground: Colors.yellow,
          unverifiedBackground: Colors.blueGrey,
          tooltipBackground: Colors.black,
          tooltipForeground: Colors.white,
        );
        expect(updated.verified, equals(Colors.red));
        expect(updated.escrow, equals(Colors.blue));
        expect(updated.gold, equals(Colors.amber));
        expect(updated.unverified, equals(Colors.grey));
        expect(updated.verifiedBackground, equals(Colors.green));
        expect(updated.escrowBackground, equals(Colors.lightBlue));
        expect(updated.goldBackground, equals(Colors.yellow));
        expect(updated.unverifiedBackground, equals(Colors.blueGrey));
        expect(updated.tooltipBackground, equals(Colors.black));
        expect(updated.tooltipForeground, equals(Colors.white));
      });
    });

    group('lerp()', () {
      test('at t=0 returns the source theme', () {
        final light = DeelBadgeThemeData.light();
        final dark = DeelBadgeThemeData.dark();
        final result = light.lerp(dark, 0.0);
        expect(result.verified, equals(light.verified));
        expect(result.escrow, equals(light.escrow));
      });

      test('at t=1 returns the target theme', () {
        final light = DeelBadgeThemeData.light();
        final dark = DeelBadgeThemeData.dark();
        final result = light.lerp(dark, 1.0);
        expect(result.verified, equals(dark.verified));
        expect(result.escrow, equals(dark.escrow));
      });

      test('at t=0.5 returns interpolated colors', () {
        final light = DeelBadgeThemeData.light();
        final dark = DeelBadgeThemeData.dark();
        final result = light.lerp(dark, 0.5);
        final expectedVerified = Color.lerp(light.verified, dark.verified, 0.5);
        expect(result.verified, equals(expectedVerified));
      });

      test('returns this when other is null', () {
        final light = DeelBadgeThemeData.light();
        // ignore: avoid_dynamic_calls
        final result = light.lerp(null, 0.5);
        expect(result.verified, equals(light.verified));
        expect(result.escrow, equals(light.escrow));
      });

      test('lerps all color fields correctly', () {
        final light = DeelBadgeThemeData.light();
        final dark = DeelBadgeThemeData.dark();
        final result = light.lerp(dark, 0.5);

        // Verify each field is the midpoint.
        expect(result.gold, equals(Color.lerp(light.gold, dark.gold, 0.5)));
        expect(
          result.unverified,
          equals(Color.lerp(light.unverified, dark.unverified, 0.5)),
        );
        expect(
          result.tooltipBackground,
          equals(
            Color.lerp(light.tooltipBackground, dark.tooltipBackground, 0.5),
          ),
        );
        expect(
          result.tooltipForeground,
          equals(
            Color.lerp(light.tooltipForeground, dark.tooltipForeground, 0.5),
          ),
        );
      });
    });
  });
}
