import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/onboarding/presentation/widgets/onboarding_trust_badges.dart';

void main() {
  group('OnboardingTrustBadges', () {
    testWidgets('hidden on compact viewport (< 840px)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: DeelmarktTheme.light,
          home: const Scaffold(body: OnboardingTrustBadges()),
        ),
      );
      await tester.pumpAndSettle();

      // Should render SizedBox.shrink (empty)
      expect(find.text('VEILIG'), findsNothing);
      expect(find.text('LOKAAL'), findsNothing);
    });

    testWidgets('visible on expanded viewport (>= 840px)', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: DeelmarktTheme.light,
          home: const Scaffold(body: OnboardingTrustBadges()),
        ),
      );
      await tester.pumpAndSettle();

      // l10n keys returned as-is in tests (no EasyLocalization)
      expect(find.textContaining('ONBOARDING.BADGE_SAFE'), findsOneWidget);
      expect(find.textContaining('ONBOARDING.BADGE_LOCAL'), findsOneWidget);
      expect(
        find.textContaining('ONBOARDING.BADGE_SUSTAINABLE'),
        findsOneWidget,
      );
    });
  });
}
