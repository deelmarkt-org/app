import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/onboarding/presentation/widgets/trust_feature_card.dart';

void main() {
  Widget buildCard({
    IconData icon = Icons.verified_user,
    String title = 'Test Title',
    String subtitle = 'Test Subtitle',
    Color iconColor = DeelmarktColors.primary,
  }) {
    return MaterialApp(
      theme: DeelmarktTheme.light,
      home: Scaffold(
        body: TrustFeatureCard(
          icon: icon,
          title: title,
          subtitle: subtitle,
          iconColor: iconColor,
        ),
      ),
    );
  }

  group('TrustFeatureCard', () {
    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(buildCard());

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
    });

    testWidgets('renders icon', (tester) async {
      await tester.pumpWidget(buildCard(icon: Icons.shield));

      expect(find.byIcon(Icons.shield), findsOneWidget);
    });

    testWidgets('applies icon color', (tester) async {
      await tester.pumpWidget(buildCard(iconColor: DeelmarktColors.success));

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, DeelmarktColors.success);
    });

    testWidgets('has Semantics label containing title and subtitle', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildCard(title: 'Escrow', subtitle: 'Veilig betalen'),
      );

      final semantics = tester.getSemantics(find.byType(TrustFeatureCard));
      expect(semantics.label, contains('Escrow'));
      expect(semantics.label, contains('Veilig betalen'));
    });

    testWidgets('renders in dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DeelmarktTheme.dark,
          home: const Scaffold(
            body: TrustFeatureCard(
              icon: Icons.lock,
              title: 'Dark Title',
              subtitle: 'Dark Sub',
              iconColor: DeelmarktColors.darkPrimary,
            ),
          ),
        ),
      );

      expect(find.text('Dark Title'), findsOneWidget);
      expect(find.text('Dark Sub'), findsOneWidget);
    });
  });
}
