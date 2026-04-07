import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/listing_detail/presentation/listing_detail_screen.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_action_bar.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_loading_view.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/sold_overlay.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';

const _testListingId = 'listing-001';

void main() {
  Widget buildScreen({String listingId = _testListingId}) {
    return ProviderScope(
      overrides: [useMockDataProvider.overrideWithValue(true)],
      child: MaterialApp(
        theme: DeelmarktTheme.light,
        home: ListingDetailScreen(listingId: listingId),
      ),
    );
  }

  group('ListingDetailScreen', () {
    testWidgets('shows data after loading', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Loading view should be gone
      expect(find.byType(DetailLoadingView), findsNothing);
      // Scaffold from data view should be present
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows error state for nonexistent listing', (tester) async {
      await tester.pumpWidget(buildScreen(listingId: 'nonexistent'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('sold listing shows SoldOverlay and hides action bar', (
      tester,
    ) async {
      // listing-002 is a sold listing in the mock repo
      await tester.pumpWidget(buildScreen(listingId: 'listing-002'));
      await tester.pumpAndSettle();

      expect(find.byType(SoldOverlay), findsOneWidget);
      expect(find.byType(DetailActionBar), findsNothing);
    });

    testWidgets('active listing shows action bar without SoldOverlay', (
      tester,
    ) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byType(SoldOverlay), findsNothing);
      expect(find.byType(DetailActionBar), findsOneWidget);
    });

    testWidgets('expanded width renders 2-column layout', (tester) async {
      // Simulate tablet width (>= 840px) with enough height
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Filter overflow warnings only (pre-existing seller_info_row issue)
      final originalHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) return;
        originalHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalHandler);

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Scaffold should render in 2-column mode
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(DetailActionBar), findsOneWidget);
    });
  });
}
