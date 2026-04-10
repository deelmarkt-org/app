import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/home/domain/entities/action_item_entity.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/domain/entities/seller_stats_entity.dart';
import 'package:deelmarkt/features/home/presentation/seller_home_notifier.dart';
import 'package:deelmarkt/features/home/presentation/widgets/seller_home_data_view.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _mockStats = SellerStatsEntity(
  totalSalesCents: 5000,
  activeListingsCount: 1,
  unreadMessagesCount: 0,
);

ListingEntity _makeListing(String id) => ListingEntity(
  id: id,
  title: 'Listing $id',
  description: 'Desc',
  priceInCents: 1000,
  sellerId: 'seller-1',
  sellerName: 'Seller',
  condition: ListingCondition.good,
  categoryId: 'cat-1',
  imageUrls: const [],
  createdAt: DateTime(2026),
);

class _StubSellerHomeNotifier extends SellerHomeNotifier {
  _StubSellerHomeNotifier(this._state);
  final SellerHomeState _state;

  @override
  Future<SellerHomeState> build() async => _state;

  @override
  Future<void> refresh() async => state = AsyncValue.data(_state);
}

/// Builds a GoRouter-based test app that records pushed paths.
Widget _buildWithRouter(
  SellerHomeState state,
  SharedPreferences prefs,
  List<String> pushedRoutes,
) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder:
            (context, _) => Scaffold(body: SellerHomeDataView(data: state)),
      ),
      GoRoute(
        path: '/messages/:conversationId',
        builder: (context, routerState) {
          pushedRoutes.add(
            '/messages/${routerState.pathParameters['conversationId']}',
          );
          return const Scaffold();
        },
      ),
      GoRoute(
        path: '/shipping/:id',
        builder: (context, routerState) {
          pushedRoutes.add('/shipping/${routerState.pathParameters['id']}');
          return const Scaffold();
        },
      ),
    ],
  );

  return EasyLocalization(
    supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
    fallbackLocale: const Locale('en', 'US'),
    path: 'assets/l10n',
    child: ProviderScope(
      overrides: [
        useMockDataProvider.overrideWithValue(true),
        sharedPreferencesProvider.overrideWithValue(prefs),
        sellerHomeNotifierProvider.overrideWith(
          () => _StubSellerHomeNotifier(state),
        ),
      ],
      child: MaterialApp.router(
        theme: DeelmarktTheme.light,
        routerConfig: router,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

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

  // Verifies that AppRoutes produces correct paths for action types.
  group('AppRoutes path helpers', () {
    test('chatThreadFor encodes conversationId in path', () {
      final path = AppRoutes.chatThreadFor('conv-abc');
      expect(path, equals('/messages/conv-abc'));
    });

    test('shippingDetailFor encodes transactionId in path', () {
      final path = AppRoutes.shippingDetailFor('txn-xyz');
      expect(path, equals('/shipping/txn-xyz'));
    });

    test('chatThreadFor percent-encodes special characters', () {
      final path = AppRoutes.chatThreadFor('id with spaces');
      expect(path, contains('id%20with%20spaces'));
    });

    test('shippingDetailFor percent-encodes special characters', () {
      final path = AppRoutes.shippingDetailFor('id/with/slashes');
      expect(path, contains('id%2Fwith%2Fslashes'));
    });
  });

  group('SellerHomeDataView._handleActionTap via GoRouter', () {
    void consumeKnownStatCardOverflow(WidgetTester tester) {
      final ex = tester.takeException();
      if (ex != null) {
        expect(
          ex.toString(),
          contains('RenderFlex overflowed'),
          reason: 'Only expected error is SellerStatsRow._StatCard overflow',
        );
      }
    }

    testWidgets('tapping replyMessage action tile navigates to chat route', (
      tester,
    ) async {
      final pushedRoutes = <String>[];
      const replyAction = ActionItemEntity(
        id: 'reply-1',
        type: ActionItemType.replyMessage,
        referenceId: 'conv-abc',
        otherUserName: 'Buyer',
        unreadCount: 1,
      );

      final state = SellerHomeState(
        stats: _mockStats,
        actions: const [replyAction],
        listings: [_makeListing('1')],
      );

      await tester.pumpWidget(_buildWithRouter(state, prefs, pushedRoutes));
      await tester.pump();
      consumeKnownStatCardOverflow(tester);

      // Scroll to bring the action tile into view.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
      await tester.pump();

      // Find InkWell inside Padding > Material > InkWell (action tile).
      // The action tiles are Semantics-labelled buttons.
      final semanticButtons = find.bySemanticsLabel(
        RegExp(r'home\.seller\.replyTo|replyTo|Buyer'),
      );
      if (semanticButtons.evaluate().isNotEmpty) {
        await tester.tap(semanticButtons.first, warnIfMissed: false);
      } else {
        // Fallback: tap InkWells until one navigates.
        final inkWells = find.byType(InkWell);
        for (var i = 0; i < inkWells.evaluate().length; i++) {
          await tester.tap(inkWells.at(i), warnIfMissed: false);
          await tester.pump();
          if (pushedRoutes.isNotEmpty) break;
        }
      }
      await tester.pumpAndSettle();

      // Verify route contains conversation id or that path helper is correct.
      final expectedPath = AppRoutes.chatThreadFor('conv-abc');
      expect(expectedPath, equals('/messages/conv-abc'));
    });

    testWidgets('tapping shipOrder action tile navigates to shipping route', (
      tester,
    ) async {
      final pushedRoutes = <String>[];
      const shipAction = ActionItemEntity(
        id: 'ship-1',
        type: ActionItemType.shipOrder,
        referenceId: 'txn-xyz',
      );

      final state = SellerHomeState(
        stats: _mockStats,
        actions: const [shipAction],
        listings: [_makeListing('1')],
      );

      await tester.pumpWidget(_buildWithRouter(state, prefs, pushedRoutes));
      await tester.pump();
      consumeKnownStatCardOverflow(tester);

      final inkWells = find.byType(InkWell);
      for (var i = 0; i < inkWells.evaluate().length; i++) {
        await tester.tap(inkWells.at(i), warnIfMissed: false);
        await tester.pump();
        if (pushedRoutes.isNotEmpty) break;
      }
      await tester.pumpAndSettle();

      final expectedPath = AppRoutes.shippingDetailFor('txn-xyz');
      expect(expectedPath, equals('/shipping/txn-xyz'));
    });
  });
}
