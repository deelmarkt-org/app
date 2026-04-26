import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/presentation/widgets/category_featured_listing_card.dart';
import 'package:deelmarkt/widgets/cards/deel_card.dart';

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
            GoRoute(
              path: '/',
              builder:
                  (_, _) => Scaffold(
                    body: SizedBox(width: 200, height: 320, child: child),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  ListingEntity makeListing({double? distanceKm}) {
    return ListingEntity(
      id: 'l1',
      sellerId: 'u1',
      sellerName: 'Seller',
      title: 'Test',
      description: 'Description',
      priceInCents: 1000,
      condition: ListingCondition.good,
      categoryId: 'c1',
      imageUrls: const [],
      location: 'Amsterdam',
      distanceKm: distanceKm,
      createdAt: DateTime(2026),
    );
  }

  testWidgets('forwards listing to DeelCard.grid', (tester) async {
    await tester.pumpWidget(
      host(
        CategoryFeaturedListingCard(
          listing: makeListing(),
          onToggleFavourite: (_) {},
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(DeelCard), findsOneWidget);
    expect(find.text('Test'), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
