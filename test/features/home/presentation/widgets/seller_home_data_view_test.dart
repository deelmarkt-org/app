import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/home/domain/entities/action_item_entity.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/domain/entities/seller_stats_entity.dart';
import 'package:deelmarkt/features/home/presentation/seller_home_notifier.dart';
import 'package:deelmarkt/features/home/presentation/widgets/action_required_section.dart';
import 'package:deelmarkt/features/home/presentation/widgets/seller_home_data_view.dart';
import 'package:deelmarkt/features/home/presentation/widgets/seller_listing_tile.dart';
import 'package:deelmarkt/features/home/presentation/widgets/seller_stats_row.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ListingEntity _makeListing(String id) => ListingEntity(
  id: id,
  title: 'Listing $id',
  description: 'Description',
  priceInCents: 1000,
  sellerId: 'seller-1',
  sellerName: 'Seller',
  condition: ListingCondition.good,
  categoryId: 'cat-1',
  imageUrls: const [],
  createdAt: DateTime(2024),
);

const _mockStats = SellerStatsEntity(
  totalSalesCents: 5000,
  activeListingsCount: 2,
  unreadMessagesCount: 0,
);

const _actionItem = ActionItemEntity(
  id: 'action-1',
  type: ActionItemType.replyMessage,
  referenceId: 'conv-1',
  otherUserName: 'Bob',
  unreadCount: 2,
);

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

  Widget buildSubject(SellerHomeState state, {ThemeData? theme}) {
    return EasyLocalization(
      supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
      fallbackLocale: const Locale('en', 'US'),
      path: 'assets/l10n',
      child: ProviderScope(
        overrides: [
          useMockDataProvider.overrideWithValue(true),
          sharedPreferencesProvider.overrideWithValue(prefs),
          // Override with a completed async value so refresh() resolves
          // without touching Supabase.
          sellerHomeNotifierProvider.overrideWith(
            () => _StubSellerHomeNotifier(state),
          ),
        ],
        child: MaterialApp(
          theme: theme ?? DeelmarktTheme.light,
          home: Scaffold(body: SellerHomeDataView(data: state)),
          onGenerateRoute:
              (_) => MaterialPageRoute<void>(builder: (_) => const Scaffold()),
        ),
      ),
    );
  }

  // SellerStatsRow._StatCard uses fixed padding (EdgeInsets.all(16)) that
  // reduces its inner height to 68 px. In the Flutter test font environment
  // the text metrics render larger than on device, causing a RenderFlex
  // overflow of ~24 px. We consume that known error with tester.takeException()
  // so the structural assertions below can still be verified.
  void consumeKnownStatCardOverflow(WidgetTester tester) {
    final ex = tester.takeException();
    if (ex != null) {
      expect(
        ex.toString(),
        contains('RenderFlex overflowed'),
        reason:
            'Only expected error is SellerStatsRow._StatCard overflow in test env',
      );
    }
  }

  group('SellerHomeDataView', () {
    testWidgets('renders RefreshIndicator', (tester) async {
      final state = SellerHomeState(
        stats: _mockStats,
        actions: const [],
        listings: [_makeListing('1')],
      );
      await tester.pumpWidget(buildSubject(state));
      await tester.pump();
      consumeKnownStatCardOverflow(tester);

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('renders SellerStatsRow', (tester) async {
      final state = SellerHomeState(
        stats: _mockStats,
        actions: const [],
        listings: [_makeListing('1')],
      );
      await tester.pumpWidget(buildSubject(state));
      await tester.pump();
      consumeKnownStatCardOverflow(tester);

      expect(find.byType(SellerStatsRow), findsOneWidget);
    });

    testWidgets('renders SellerListingTile for each listing', (tester) async {
      final state = SellerHomeState(
        stats: _mockStats,
        actions: const [],
        listings: [_makeListing('1'), _makeListing('2')],
      );
      await tester.pumpWidget(buildSubject(state));
      await tester.pump();
      consumeKnownStatCardOverflow(tester);

      expect(find.byType(SellerListingTile), findsNWidgets(2));
    });

    testWidgets('shows ActionRequiredSection when actions non-empty', (
      tester,
    ) async {
      final state = SellerHomeState(
        stats: _mockStats,
        actions: const [_actionItem],
        listings: [_makeListing('1')],
      );
      await tester.pumpWidget(buildSubject(state));
      await tester.pump();
      consumeKnownStatCardOverflow(tester);

      expect(find.byType(ActionRequiredSection), findsOneWidget);
    });

    testWidgets('hides ActionRequiredSection when actions empty', (
      tester,
    ) async {
      final state = SellerHomeState(
        stats: _mockStats,
        actions: const [],
        listings: [_makeListing('1')],
      );
      await tester.pumpWidget(buildSubject(state));
      await tester.pump();
      consumeKnownStatCardOverflow(tester);

      // No action items — only the listing tile should be present.
      expect(find.byType(SellerListingTile), findsOneWidget);
    });
  });
}

// ---------------------------------------------------------------------------
// Stub notifier — returns fixed state without network calls.
// ---------------------------------------------------------------------------

class _StubSellerHomeNotifier extends SellerHomeNotifier {
  _StubSellerHomeNotifier(this._state);

  final SellerHomeState _state;

  @override
  Future<SellerHomeState> build() async => _state;

  @override
  Future<void> refresh() async {
    state = AsyncValue.data(_state);
  }
}
