import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/presentation/category_detail_notifier.dart';
import 'package:deelmarkt/features/home/presentation/widgets/category_detail_data_view.dart';

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

  CategoryDetailState state({
    List<CategoryEntity> subs = const [],
    List<ListingEntity> featured = const [],
  }) {
    return CategoryDetailState(
      parent: const CategoryEntity(id: 'c1', name: 'Bikes', icon: 'bike'),
      subcategories: subs,
      featuredListings: featured,
    );
  }

  testWidgets(
    'renders empty placeholder when subs and featured are both empty',
    (tester) async {
      await tester.pumpWidget(
        host(CategoryDetailDataView(state: state(), onToggleFavourite: (_) {})),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SliverFillRemaining), findsOneWidget);
    },
  );

  testWidgets('renders the chips row when subcategories are present', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        CategoryDetailDataView(
          state: state(
            subs: const [CategoryEntity(id: 's1', name: 'Sub', icon: 'gear')],
          ),
          onToggleFavourite: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sub'), findsOneWidget);
  });
}
