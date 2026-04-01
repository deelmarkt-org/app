import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/listing_detail/presentation/listing_detail_screen.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_loading_view.dart';
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
  });
}
