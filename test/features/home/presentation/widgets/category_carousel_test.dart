import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';
import 'package:deelmarkt/features/home/presentation/widgets/category_carousel.dart';

final _testCategories = [
  const CategoryEntity(id: 'cat-1', name: 'Voertuigen', icon: 'car'),
  const CategoryEntity(id: 'cat-2', name: 'Elektronica', icon: 'devices'),
  const CategoryEntity(id: 'cat-3', name: 'Kleding', icon: 't-shirt'),
];

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Widget buildCarousel({ValueChanged<CategoryEntity>? onCategoryTap}) {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: MaterialApp(
        theme: DeelmarktTheme.light,
        home: Scaffold(
          body: CategoryCarousel(
            categories: _testCategories,
            onCategoryTap: onCategoryTap ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('CategoryCarousel', () {
    testWidgets('renders all category names', (tester) async {
      await tester.pumpWidget(buildCarousel());
      await tester.pumpAndSettle();

      expect(find.text('Voertuigen'), findsOneWidget);
      expect(find.text('Elektronica'), findsOneWidget);
      expect(find.text('Kleding'), findsOneWidget);
    });

    testWidgets('tapping a category calls onCategoryTap', (tester) async {
      CategoryEntity? tappedCategory;
      await tester.pumpWidget(
        buildCarousel(onCategoryTap: (cat) => tappedCategory = cat),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Voertuigen'));
      expect(tappedCategory?.id, 'cat-1');
    });

    testWidgets('renders icons', (tester) async {
      await tester.pumpWidget(buildCarousel());
      await tester.pumpAndSettle();

      expect(find.byType(Icon), findsNWidgets(3));
    });

    testWidgets('category pills use circular shape', (tester) async {
      await tester.pumpWidget(buildCarousel());
      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final circularContainer = containers.where((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.shape == BoxShape.circle;
        }
        return false;
      });
      expect(circularContainer, isNotEmpty);
    });

    testWidgets('uses InkWell for focus support', (tester) async {
      await tester.pumpWidget(buildCarousel());
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsNWidgets(3));
    });
  });
}
