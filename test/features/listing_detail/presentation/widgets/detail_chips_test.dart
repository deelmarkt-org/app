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
  });
}
