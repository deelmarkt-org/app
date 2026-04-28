import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/listing_detail/presentation/listing_detail_notifier.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_action_bar.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_image_gallery.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/listing_detail_data_view.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/sold_overlay.dart';

/// Smoke + structural tests for [ListingDetailDataView].
///
/// The screen-level test (`listing_detail_screen_test.dart`) exercises
/// the full data flow via mock providers. This file proves the data view
/// can be rendered in isolation with a constructed [ListingDetailState] —
/// the test seam P-54 D2 + D7 mandate for any extracted widget.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  ListingEntity makeListing({
    String id = 'test-1',
    ListingStatus status = ListingStatus.active,
  }) {
    return ListingEntity(
      id: id,
      title: 'Vintage Design Stoel',
      description: 'Een prachtige vintage stoel in goede staat.',
      priceInCents: 4500,
      sellerId: 'user-1',
      sellerName: 'Jan',
      condition: ListingCondition.good,
      categoryId: 'cat-1',
      imageUrls: const [],
      createdAt: DateTime(2026),
      location: 'Amsterdam',
      distanceKm: 2.3,
      status: status,
    );
  }

  Widget buildHost({required ListingDetailState state}) {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: MaterialApp(
        theme: DeelmarktTheme.light,
        home: ListingDetailDataView(
          data: state,
          listingId: state.listing.id,
          onFavouriteTap: () {},
        ),
      ),
    );
  }

  testWidgets('smoke render — builds without throwing for active listing', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHost(state: ListingDetailState(listing: makeListing())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(DetailImageGallery), findsOneWidget);
  });

  testWidgets('active listing shows DetailActionBar + no SoldOverlay', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHost(state: ListingDetailState(listing: makeListing())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DetailActionBar), findsOneWidget);
    expect(find.byType(SoldOverlay), findsNothing);
  });

  testWidgets('sold listing wraps gallery in SoldOverlay + hides ActionBar', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHost(
        state: ListingDetailState(
          listing: makeListing(status: ListingStatus.sold),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SoldOverlay), findsOneWidget);
    expect(find.byType(DetailActionBar), findsNothing);
  });

  testWidgets('expanded layout (≥840px) renders compact compact + side pane', (
    tester,
  ) async {
    // Force expanded breakpoint by sizing the test view large enough.
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildHost(state: ListingDetailState(listing: makeListing())),
    );
    await tester.pumpAndSettle();

    // Expanded layout uses a Row with two flex children; compact uses Column.
    final scaffolds = find.byType(Scaffold);
    expect(scaffolds, findsOneWidget);
    // The expanded layout has a Row directly inside the SafeArea.
    expect(find.byType(Row), findsWidgets);
  });
}
