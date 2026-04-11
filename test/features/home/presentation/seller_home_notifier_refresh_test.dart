import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/presentation/seller_home_notifier.dart';

import '_seller_home_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SellerHomeNotifier.refresh', () {
    test('refresh re-fetches and updates state', () async {
      final user = makeTestUser(email: 'a@b.com');
      var callCount = 0;

      final container = await makeSellerContainer(
        user: user,
        statsResult: (_) async {
          callCount++;
          return sellerTestStats;
        },
      );
      addTearDown(container.dispose);

      container.listen(sellerHomeNotifierProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(container.read(sellerHomeNotifierProvider).hasValue, isTrue);
      final countAfterBuild = callCount;

      await container.read(sellerHomeNotifierProvider.notifier).refresh();

      expect(callCount, greaterThan(countAfterBuild));
      expect(container.read(sellerHomeNotifierProvider).hasValue, isTrue);
    });

    test('refresh rolls back to previous state when fetch fails', () async {
      final user = makeTestUser(email: 'x@y.com');
      var shouldFail = false;

      final container = await makeSellerContainer(
        user: user,
        statsResult: (_) async {
          if (shouldFail) throw Exception('network error');
          return sellerTestStats;
        },
        actionsResult: (_) async {
          if (shouldFail) throw Exception('network error');
          return sellerTestActions;
        },
        listingsResult: (_) async {
          if (shouldFail) throw Exception('network error');
          return [makeTestListing('1')];
        },
      );
      addTearDown(container.dispose);

      container.listen(sellerHomeNotifierProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(container.read(sellerHomeNotifierProvider).hasValue, isTrue);
      final previous = container.read(sellerHomeNotifierProvider).requireValue;

      shouldFail = true;
      await container.read(sellerHomeNotifierProvider.notifier).refresh();

      final afterRefresh = container.read(sellerHomeNotifierProvider);
      expect(afterRefresh.hasValue, isTrue);
      expect(afterRefresh.requireValue, equals(previous));
    });

    test('stays in error when no previous state to roll back', () async {
      final user = makeTestUser(email: 'error@test.com');

      final container = await makeSellerContainer(
        user: user,
        statsResult: (_) async => throw Exception('fail'),
        actionsResult: (_) async => throw Exception('fail'),
        listingsResult: (_) async => throw Exception('fail'),
      );
      addTearDown(container.dispose);

      container.listen(sellerHomeNotifierProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(container.read(sellerHomeNotifierProvider).hasError, isTrue);

      await container.read(sellerHomeNotifierProvider.notifier).refresh();

      expect(container.read(sellerHomeNotifierProvider).hasError, isTrue);
    });
  });
}
