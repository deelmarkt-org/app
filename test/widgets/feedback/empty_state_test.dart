import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';
import 'package:deelmarkt/widgets/feedback/empty_state.dart';

import 'feedback_test_helper.dart';

void main() {
  group('EmptyState variant rendering', () {
    for (final variant in EmptyStateVariant.values) {
      testWidgets('${variant.name} renders correct icon and text', (
        tester,
      ) async {
        var tapped = false;
        await tester.pumpWidget(
          buildFeedbackApp(
            child: EmptyState(variant: variant, onAction: () => tapped = true),
          ),
        );

        expect(find.byIcon(variant.icon), findsOneWidget);
        expect(find.text(variant.messageKey), findsOneWidget);
        expect(find.text(variant.actionKey), findsOneWidget);

        await tester.tap(find.byType(DeelButton));
        expect(tapped, isTrue);
      });
    }
  });

  group('EmptyState.custom', () {
    testWidgets('renders custom icon, message, and action', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildFeedbackApp(
          child: EmptyState.custom(
            icon: PhosphorIcons.star(),
            message: 'Custom empty message',
            actionLabel: 'Custom action',
            onAction: () => tapped = true,
          ),
        ),
      );

      expect(find.byIcon(PhosphorIcons.star()), findsOneWidget);
      expect(find.text('Custom empty message'), findsOneWidget);
      expect(find.text('Custom action'), findsOneWidget);

      await tester.tap(find.byType(DeelButton));
      expect(tapped, isTrue);
    });
  });

  group('EmptyState layout', () {
    testWidgets('has Semantics label', (tester) async {
      await tester.pumpWidget(
        buildFeedbackApp(
          child: EmptyState(variant: EmptyStateVariant.search, onAction: () {}),
        ),
      );
      final semantics = tester.getSemantics(find.byType(EmptyState).first);
      expect(semantics.label, contains('a11y.emptyState'));
    });

    testWidgets('no overflow at 320px width', (tester) async {
      await tester.pumpWidget(
        buildFeedbackApp(
          child: SizedBox(
            width: 320,
            child: EmptyState(
              variant: EmptyStateVariant.myListings,
              onAction: () {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses DeelButton secondary variant', (tester) async {
      await tester.pumpWidget(
        buildFeedbackApp(
          child: EmptyState(
            variant: EmptyStateVariant.favorites,
            onAction: () {},
          ),
        ),
      );
      final button = tester.widget<DeelButton>(find.byType(DeelButton));
      expect(button.variant, DeelButtonVariant.secondary);
      expect(button.size, DeelButtonSize.medium);
      expect(button.fullWidth, isFalse);
    });

    testWidgets('renders in dark mode', (tester) async {
      await tester.pumpWidget(
        buildFeedbackApp(
          theme: DeelmarktTheme.dark,
          child: EmptyState(variant: EmptyStateVariant.orders, onAction: () {}),
        ),
      );
      expect(find.byType(EmptyState), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
