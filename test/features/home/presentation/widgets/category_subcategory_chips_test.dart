import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';
import 'package:deelmarkt/features/home/presentation/widgets/category_subcategory_chips.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Widget host(Widget child) {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => Scaffold(body: child)),
          ],
        ),
      ),
    );
  }

  testWidgets('renders one chip per subcategory', (tester) async {
    final subs = [
      const CategoryEntity(id: 's1', name: 'Sub One', icon: 'gear'),
      const CategoryEntity(id: 's2', name: 'Sub Two', icon: 'gear'),
    ];
    await tester.pumpWidget(
      host(CategorySubcategoryChips(subcategories: subs)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sub One'), findsOneWidget);
    expect(find.text('Sub Two'), findsOneWidget);
  });

  testWidgets('renders empty Wrap when subcategories is empty', (tester) async {
    await tester.pumpWidget(
      host(const CategorySubcategoryChips(subcategories: [])),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Wrap), findsOneWidget);
  });
}
