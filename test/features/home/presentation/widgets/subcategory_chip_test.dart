import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';
import 'package:deelmarkt/features/home/presentation/widgets/subcategory_chip.dart';

const _testCategory = CategoryEntity(
  id: 'cat-phones',
  name: 'Telefoons',
  icon: 'phone',
  parentId: 'cat-electronics',
);

void main() {
  Widget buildChip({VoidCallback? onTap}) {
    return MaterialApp(
      theme: DeelmarktTheme.light,
      home: Scaffold(
        body: SubcategoryChip(category: _testCategory, onTap: onTap ?? () {}),
      ),
    );
  }

  group('SubcategoryChip', () {
    testWidgets('renders category name', (tester) async {
      await tester.pumpWidget(buildChip());
      await tester.pumpAndSettle();

      expect(find.text('Telefoons'), findsOneWidget);
    });

    testWidgets('tap fires onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildChip(onTap: () => tapped = true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Telefoons'));
      expect(tapped, isTrue);
    });

    testWidgets('has Semantics label', (tester) async {
      await tester.pumpWidget(buildChip());
      await tester.pumpAndSettle();

      final semantics = tester.getSemantics(find.byType(SubcategoryChip));
      expect(semantics.label, contains('Telefoons'));
    });

    testWidgets('min height >= 44px for touch target compliance', (
      tester,
    ) async {
      await tester.pumpWidget(buildChip());
      await tester.pumpAndSettle();

      final container = tester.firstWidget<Container>(
        find.descendant(
          of: find.byType(SubcategoryChip),
          matching: find.byType(Container),
        ),
      );
      expect(container.constraints?.minHeight, greaterThanOrEqualTo(44));
    });

    testWidgets('renders icon', (tester) async {
      await tester.pumpWidget(buildChip());
      await tester.pumpAndSettle();

      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('uses InkWell for interaction', (tester) async {
      await tester.pumpWidget(buildChip());
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsOneWidget);
    });
  });
}
