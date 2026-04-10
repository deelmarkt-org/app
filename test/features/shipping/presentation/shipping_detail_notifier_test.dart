import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/shipping/data/mock/mock_shipping_repository.dart';
import 'package:deelmarkt/features/shipping/domain/entities/shipping_label.dart';
import 'package:deelmarkt/features/shipping/presentation/shipping_detail_notifier.dart';

void main() {
  group('shippingDetailProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          shippingRepositoryProvider.overrideWithValue(
            MockShippingRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
    });

    test('returns label + events for known ID', () async {
      final state = await container.read(
        shippingDetailProvider('ship-001').future,
      );

      expect(state.label.id, 'ship-001');
      expect(state.label.carrier, ShippingCarrier.postnl);
      expect(state.events, hasLength(3));
    });

    test('throws for unknown ID', () async {
      expect(
        () => container.read(shippingDetailProvider('nonexistent').future),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('parcelShopsProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          shippingRepositoryProvider.overrideWithValue(
            MockShippingRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
    });

    test('returns parcel shops', () async {
      final shops = await container.read(parcelShopsProvider('1012RR').future);

      expect(shops, isNotEmpty);
    });
  });
}
