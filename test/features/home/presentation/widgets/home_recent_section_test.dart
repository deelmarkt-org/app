import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/core/services/unleash_service.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/presentation/widgets/home_recent_section.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget host(List<Widget> slivers) {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: ProviderScope(
        overrides: [
          useMockDataProvider.overrideWithValue(true),
          sharedPreferencesProvider.overrideWithValue(prefs),
          isFeatureEnabledProvider(
            FeatureFlags.listingsEscrowBadge,
          ).overrideWith((ref) => false),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder:
                    (_, _) =>
                        Scaffold(body: CustomScrollView(slivers: slivers)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('HomeRecentHeader renders inside a sliver', (tester) async {
    await tester.pumpWidget(host(const [HomeRecentHeader()]));
    await tester.pumpAndSettle();
    expect(find.byType(SliverToBoxAdapter), findsOneWidget);
  });

  testWidgets('HomeRecentRow renders a horizontal ListView for the listings', (
    tester,
  ) async {
    final listings = [
      ListingEntity(
        id: 'l1',
        sellerId: 'u1',
        sellerName: 'Seller',
        title: 'Recent A',
        description: '',
        priceInCents: 500,
        condition: ListingCondition.good,
        categoryId: 'c1',
        imageUrls: const [],
        location: 'A',
        createdAt: DateTime(2026),
      ),
    ];
    await tester.pumpWidget(
      host([HomeRecentRow(listings: listings, onToggleFavourite: (_) {})]),
    );
    await tester.pump();
    expect(find.byType(HomeRecentRow), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
