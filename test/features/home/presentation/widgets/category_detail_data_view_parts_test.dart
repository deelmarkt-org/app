import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/features/home/presentation/widgets/category_detail_data_view_parts.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Widget host(Widget sliver) {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: MaterialApp(
        home: Scaffold(body: CustomScrollView(slivers: [sliver])),
      ),
    );
  }

  testWidgets('CategoryDetailHero renders the parent name in the title key', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const CategoryDetailHero(parentName: 'Bikes')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('CategoryDetailFeaturedHeader renders inside a sliver', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const CategoryDetailFeaturedHeader(parentName: 'Bikes')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SliverToBoxAdapter), findsOneWidget);
  });
}
