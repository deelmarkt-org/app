import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/core/services/unleash_service.dart';
import 'package:deelmarkt/widgets/badges/deel_badge.dart';
import 'package:deelmarkt/widgets/badges/deel_badge_data.dart';
import 'package:deelmarkt/widgets/cards/escrow_aware_listing_card.dart';

ListingEntity _listing({bool isEscrowAvailable = true}) => ListingEntity(
  id: 'listing-1',
  title: 'Vintage design stoel',
  description: 'Een mooie vintage stoel',
  priceInCents: 4500,
  sellerId: 'seller-1',
  sellerName: 'Jan de Vries',
  condition: ListingCondition.good,
  categoryId: 'cat-1',
  imageUrls: const ['https://example.com/stoel.jpg'],
  createdAt: DateTime(2026, 4, 20),
  isEscrowAvailable: isEscrowAvailable,
);

Widget _host({required bool flagEnabled, required ListingEntity listing}) {
  return EasyLocalization(
    supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
    fallbackLocale: const Locale('en', 'US'),
    path: 'assets/l10n',
    child: ProviderScope(
      overrides: [
        isFeatureEnabledProvider(
          FeatureFlags.listingsEscrowBadge,
        ).overrideWith((ref) => flagEnabled),
      ],
      child: MaterialApp(
        theme: DeelmarktTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 180,
              child: EscrowAwareListingCard(
                listing: listing,
                onTap: () {},
                onFavouriteTap: () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('EscrowAwareListingCard', () {
    testWidgets('hides badge when flag is OFF even if entity is eligible', (
      tester,
    ) async {
      await tester.pumpWidget(_host(flagEnabled: false, listing: _listing()));
      await tester.pumpAndSettle();

      expect(find.byType(DeelBadge), findsNothing);
      // Regression guard: the rest of the card must still render when the
      // badge is suppressed — a silent `SizedBox.shrink()` would pass the
      // `findsNothing` check above but break the listing grid entirely.
      expect(find.text('Vintage design stoel'), findsOneWidget);
    });

    testWidgets('hides badge when flag is ON but entity is ineligible', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(flagEnabled: true, listing: _listing(isEscrowAvailable: false)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DeelBadge), findsNothing);
      expect(find.text('Vintage design stoel'), findsOneWidget);
    });

    testWidgets('shows badge only when flag ON AND entity eligible', (
      tester,
    ) async {
      await tester.pumpWidget(_host(flagEnabled: true, listing: _listing()));
      await tester.pumpAndSettle();

      expect(find.byType(DeelBadge), findsOneWidget);
      final badge = tester.widget<DeelBadge>(find.byType(DeelBadge));
      expect(badge.type, DeelBadgeType.escrowProtected);
    });

    testWidgets('hides badge when both flag OFF and entity ineligible', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(flagEnabled: false, listing: _listing(isEscrowAvailable: false)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DeelBadge), findsNothing);
    });
  });
}
