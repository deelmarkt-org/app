import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/widgets/cards/stat_card.dart';

Widget _host({required ThemeData theme, required Widget child}) {
  return MaterialApp(theme: theme, home: Scaffold(body: Center(child: child)));
}

void main() {
  group('StatCard', () {
    testWidgets('renders value and label', (tester) async {
      await tester.pumpWidget(
        _host(
          theme: DeelmarktTheme.light,
          child: const StatCard(
            icon: Icons.trending_up,
            iconColor: DeelmarktColors.success,
            value: '€ 1.247',
            label: 'Totale verkopen',
          ),
        ),
      );

      expect(find.text('€ 1.247'), findsOneWidget);
      expect(find.text('Totale verkopen'), findsOneWidget);
    });

    testWidgets(
      'wraps content in a Semantics node that combines value + label',
      (tester) async {
        await tester.pumpWidget(
          _host(
            theme: DeelmarktTheme.light,
            child: const StatCard(
              icon: Icons.inventory,
              iconColor: DeelmarktColors.secondary,
              value: '8',
              label: 'Actieve advertenties',
            ),
          ),
        );

        final semantics = tester.widget<Semantics>(
          find
              .descendant(
                of: find.byType(StatCard),
                matching: find.byType(Semantics),
              )
              .first,
        );
        expect(semantics.properties.label, '8 Actieve advertenties');
        // Prevents screen readers from also announcing the inner Text nodes —
        // otherwise TalkBack/VoiceOver would triple-announce the card.
        expect(semantics.excludeSemantics, isTrue);
      },
    );

    testWidgets('hides the badge dot when showBadge is false', (tester) async {
      await tester.pumpWidget(
        _host(
          theme: DeelmarktTheme.light,
          child: const StatCard(
            icon: Icons.chat_bubble,
            iconColor: DeelmarktColors.primary,
            value: '0',
            label: 'Ongelezen berichten',
          ),
        ),
      );

      expect(find.byKey(const Key('stat_card_badge')), findsNothing);
    });

    testWidgets('shows the badge dot when showBadge is true', (tester) async {
      await tester.pumpWidget(
        _host(
          theme: DeelmarktTheme.light,
          child: const StatCard(
            icon: Icons.chat_bubble,
            iconColor: DeelmarktColors.primary,
            value: '3',
            label: 'Ongelezen berichten',
            showBadge: true,
          ),
        ),
      );

      expect(find.byKey(const Key('stat_card_badge')), findsOneWidget);
    });

    testWidgets('exposes a fixed 140-pixel width via StatCard.width', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          theme: DeelmarktTheme.light,
          child: const StatCard(
            icon: Icons.trending_up,
            iconColor: DeelmarktColors.success,
            value: '€ 0',
            label: 'Totale verkopen',
          ),
        ),
      );

      expect(StatCard.width, 140);
      final size = tester.getSize(find.byType(StatCard));
      expect(size.width, StatCard.width);
    });

    testWidgets('uses the dark surface token in dark mode', (tester) async {
      await tester.pumpWidget(
        _host(
          theme: DeelmarktTheme.dark,
          child: const StatCard(
            icon: Icons.trending_up,
            iconColor: DeelmarktColors.success,
            value: '€ 1.247',
            label: 'Totale verkopen',
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(StatCard),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, DeelmarktColors.darkSurface);
    });
  });
}
