import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_chips.dart';

void main() {
  group('ConditionChip', () {
    Widget buildChip({ListingCondition condition = ListingCondition.good}) {
      return MaterialApp(
        theme: DeelmarktTheme.light,
        home: Scaffold(body: ConditionChip(condition: condition)),
      );
    }

    testWidgets('renders condition label', (tester) async {
      await tester.pumpWidget(buildChip());
      await tester.pump();
      // The chip should render some text for the condition
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('has Semantics label', (tester) async {
      await tester.pumpWidget(buildChip());
      await tester.pump();
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('renders with dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DeelmarktTheme.dark,
          home: const Scaffold(
            body: ConditionChip(condition: ListingCondition.likeNew),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ConditionChip), findsOneWidget);
    });

    testWidgets('renders newWithTags condition', (tester) async {
      await tester.pumpWidget(
        buildChip(condition: ListingCondition.newWithTags),
      );
      await tester.pump();
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('renders newWithoutTags condition', (tester) async {
      await tester.pumpWidget(
        buildChip(condition: ListingCondition.newWithoutTags),
      );
      await tester.pump();
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('renders likeNew condition', (tester) async {
      await tester.pumpWidget(buildChip(condition: ListingCondition.likeNew));
      await tester.pump();
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('renders good condition', (tester) async {
      await tester.pumpWidget(buildChip());
      await tester.pump();
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('renders fair condition', (tester) async {
      await tester.pumpWidget(buildChip(condition: ListingCondition.fair));
      await tester.pump();
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('renders poor condition', (tester) async {
      await tester.pumpWidget(buildChip(condition: ListingCondition.poor));
      await tester.pump();
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('all 6 ListingCondition variants render a Text widget', (
      tester,
    ) async {
      for (final condition in ListingCondition.values) {
        await tester.pumpWidget(buildChip(condition: condition));
        await tester.pump();
        expect(
          find.byType(Text),
          findsOneWidget,
          reason: 'Expected Text for condition ${condition.name}',
        );
      }
    });
  });

  group('CategoryChip', () {
    Widget buildChip({String name = 'Meubels'}) {
      return MaterialApp(
        theme: DeelmarktTheme.light,
        home: Scaffold(body: CategoryChip(name: name)),
      );
    }

    testWidgets('renders category name', (tester) async {
      await tester.pumpWidget(buildChip());
      await tester.pump();
      expect(find.text('Meubels'), findsOneWidget);
    });

    testWidgets('renders with dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DeelmarktTheme.dark,
          home: const Scaffold(body: CategoryChip(name: 'Sport')),
        ),
      );
      await tester.pump();
      expect(find.text('Sport'), findsOneWidget);
    });

    testWidgets('has Semantics label', (tester) async {
      await tester.pumpWidget(buildChip(name: 'Elektronica'));
      await tester.pump();

      expect(find.byType(Semantics), findsWidgets);

      final semanticsWidgets = tester.widgetList<Semantics>(
        find.byType(Semantics),
      );
      final hasNameLabel = semanticsWidgets.any(
        (s) => s.properties.label == 'Elektronica',
      );
      expect(hasNameLabel, isTrue);
    });
  });
}
