import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deelmarkt/features/onboarding/presentation/onboarding_screen.dart';

import '../../../../test/helpers/pump_app.dart';

void main() {
  group('OnboardingScreen', () {
    testWidgets('renders shield icon', (tester) async {
      await pumpTestScreen(tester, const OnboardingScreen());

      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('renders app name text', (tester) async {
      await pumpTestScreen(tester, const OnboardingScreen());

      // .tr() returns the key path in tests
      expect(find.text('app.name'), findsOneWidget);
    });

    testWidgets('renders tagline', (tester) async {
      await pumpTestScreen(tester, const OnboardingScreen());

      expect(find.text('app.tagline'), findsOneWidget);
    });

    testWidgets('renders with Scaffold', (tester) async {
      await pumpTestScreen(tester, const OnboardingScreen());

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
