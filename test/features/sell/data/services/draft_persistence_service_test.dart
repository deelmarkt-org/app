import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/sell/data/services/draft_persistence_service.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';

void main() {
  late DraftPersistenceService service;

  Future<void> initService([Map<String, Object> values = const {}]) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    service = DraftPersistenceService(prefs);
  }

  group('DraftPersistenceService', () {
    test('save then restore round-trips all fields', () async {
      await initService();

      const state = ListingCreationState(
        step: ListingCreationStep.quality,
        imageFiles: ['img1.jpg', 'img2.jpg', 'img3.jpg'],
        title: 'Vintage lamp',
        description: 'A beautiful vintage lamp from the 1960s',
        categoryL1Id: 'home',
        categoryL2Id: 'lighting',
        condition: ListingCondition.likeNew,
        priceInCents: 7500,
        shippingCarrier: ShippingCarrier.postnl,
        weightRange: WeightRange.twoToFive,
        location: '1012AB',
      );

      await service.save(state);
      final restored = service.restore();

      expect(restored, isNotNull);
      expect(restored!.imageFiles, ['img1.jpg', 'img2.jpg', 'img3.jpg']);
      expect(restored.title, 'Vintage lamp');
      expect(restored.description, 'A beautiful vintage lamp from the 1960s');
      expect(restored.categoryL1Id, 'home');
      expect(restored.categoryL2Id, 'lighting');
      expect(restored.condition, ListingCondition.likeNew);
      expect(restored.priceInCents, 7500);
      expect(restored.shippingCarrier, ShippingCarrier.postnl);
      expect(restored.weightRange, WeightRange.twoToFive);
      expect(restored.location, '1012AB');
    });

    test('restore returns null when no data stored', () async {
      await initService();

      final result = service.restore();

      expect(result, isNull);
    });

    test('restore returns null when invalid JSON', () async {
      await initService({'listing_creation_draft': 'not-valid-json{'});

      final result = service.restore();

      expect(result, isNull);
    });

    test(
      'restore always returns step = photos regardless of saved step',
      () async {
        await initService();

        const state = ListingCreationState(
          step: ListingCreationStep.publishing,
          title: 'Test',
        );

        await service.save(state);
        final restored = service.restore();

        expect(restored, isNotNull);
        expect(restored!.step, ListingCreationStep.photos);
      },
    );

    test('clear removes the draft', () async {
      await initService();

      const state = ListingCreationState(title: 'To be cleared');
      await service.save(state);

      expect(service.restore(), isNotNull);

      await service.clear();

      expect(service.restore(), isNull);
    });
  });
}
