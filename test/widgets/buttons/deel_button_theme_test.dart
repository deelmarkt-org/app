import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/deel_button_theme.dart';

void main() {
  group('DeelButtonThemeData', () {
    test('light factory has correct primary colours', () {
      final theme = DeelButtonThemeData.light();
      expect(theme.primaryBackground, DeelmarktColors.primary);
      expect(theme.primaryForeground, DeelmarktColors.white);
    });

    test('dark factory has correct primary colours', () {
      final theme = DeelButtonThemeData.dark();
      expect(theme.primaryBackground, DeelmarktColors.darkPrimary);
      expect(theme.primaryForeground, DeelmarktColors.darkOnPrimary);
    });

    test('lerp interpolates between themes', () {
      final light = DeelButtonThemeData.light();
      final dark = DeelButtonThemeData.dark();
      final mid = light.lerp(dark, 0.5);

      expect(
        mid.primaryBackground,
        Color.lerp(light.primaryBackground, dark.primaryBackground, 0.5),
      );
    });

    test('copyWith returns new instance with overridden values', () {
      final original = DeelButtonThemeData.light();
      final modified = original.copyWith(primaryBackground: Colors.blue);

      expect(modified.primaryBackground, Colors.blue);
      expect(modified.primaryForeground, original.primaryForeground);
    });
  });
}
