import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';
import 'package:deelmarkt/features/home/presentation/widgets/category_card.dart';

const _testCategory = CategoryEntity(
  id: 'cat-electronics',
  name: 'Elektronica',
  icon: 'device-mobile',
  listingCount: 567,
);

void main() {
  Widget buildCard({VoidCallback? onTap}) {
    return MaterialApp(
      theme: DeelmarktTheme.light,
      home: Scaffold(
        body: CategoryCard(category: _testCategory, onTap: onTap ?? () {}),
      ),
    );
  }

  group('CategoryCard', () {
    testWidgets('renders category name', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(find.text('Elektronica'), findsOneWidget);
    });

    testWidgets('renders icon', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('renders caret right chevron', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      // Find the caret right icon among the Icon widgets
      final icons = tester.widgetList<Icon>(find.byType(Icon));
      final hasChevron = icons.any(
        (icon) =>
            icon.icon == PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
      );
      expect(hasChevron, isTrue);
    });

    testWidgets('tap fires onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(buildCard(onTap: () => tapped = true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Elektronica'));
      expect(tapped, isTrue);
    });

    testWidgets('has Semantics label', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      final semantics = tester.getSemantics(find.byType(CategoryCard));
      expect(semantics.label, contains('Elektronica'));
    });

    testWidgets('uses InkWell for interaction', (tester) async {
      await tester.pumpWidget(buildCard());
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsOneWidget);
    });
  });
}
