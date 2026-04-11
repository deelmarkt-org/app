import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/presentation/seller_home_notifier.dart';

import '_seller_home_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SellerHomeNotifier.build', () {
    test('throws StateError when user is null', () async {
      final container = await makeSellerContainer(user: null);
      addTearDown(container.dispose);

      container.listen(sellerHomeNotifierProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final result = container.read(sellerHomeNotifierProvider);
      expect(result.hasError, isTrue);
      expect(result.error, isA<StateError>());
      expect((result.error as StateError).message, contains('authentication'));
    });

    test('sets userName from display_name in userMetadata', () async {
      final user = makeTestUser(
        email: 'user@example.com',
        userMetadata: {'display_name': 'Alice'},
      );
      final container = await makeSellerContainer(user: user);
      addTearDown(container.dispose);

      container.listen(sellerHomeNotifierProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final result = container.read(sellerHomeNotifierProvider);
      expect(result.hasValue, isTrue);
      expect(result.requireValue.userName, equals('Alice'));
    });

    test('populates stats and actions from stub use cases', () async {
      final user = makeTestUser(email: 'u@example.com');
      final container = await makeSellerContainer(user: user);
      addTearDown(container.dispose);

      container.listen(sellerHomeNotifierProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final result = container.read(sellerHomeNotifierProvider);
      expect(result.hasValue, isTrue);
      expect(result.requireValue.stats, equals(sellerTestStats));
      expect(result.requireValue.actions, equals(sellerTestActions));
    });

    test('falls back to email prefix when display_name is absent', () async {
      final user = makeTestUser(
        email: 'jan@deelmarkt.nl',
        userMetadata: const {},
      );
      final container = await makeSellerContainer(user: user);
      addTearDown(container.dispose);

      container.listen(sellerHomeNotifierProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final result = container.read(sellerHomeNotifierProvider);
      expect(result.hasValue, isTrue);
      expect(result.requireValue.userName, equals('jan'));
    });

    test('userName is null when no display_name and no email', () async {
      final user = makeTestUser(userMetadata: const {});
      final container = await makeSellerContainer(user: user);
      addTearDown(container.dispose);

      container.listen(sellerHomeNotifierProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final result = container.read(sellerHomeNotifierProvider);
      expect(result.hasValue, isTrue);
      expect(result.requireValue.userName, isNull);
    });

    test('invokes all three use cases during build', () async {
      final called = <String>{};
      final user = makeTestUser(id: 'u1', email: 'u@example.com');

      final container = await makeSellerContainer(
        user: user,
        statsResult: (_) async {
          called.add('stats');
          return sellerTestStats;
        },
        actionsResult: (_) async {
          called.add('actions');
          return sellerTestActions;
        },
        listingsResult: (_) async {
          called.add('listings');
          return [makeTestListing('1')];
        },
      );
      addTearDown(container.dispose);

      container.listen(sellerHomeNotifierProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(called, containsAll(['stats', 'actions', 'listings']));
    });
  });
}
