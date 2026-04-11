import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state_copy_with.dart';

void main() {
  group('ListingCreationState.initial()', () {
    test('returns correct defaults', () {
      final state = ListingCreationState.initial();

      expect(state.step, ListingCreationStep.photos);
      expect(state.imageFiles, isEmpty);
      expect(state.title, '');
      expect(state.description, '');
      expect(state.categoryL1Id, isNull);
      expect(state.categoryL2Id, isNull);
      expect(state.condition, isNull);
      expect(state.priceInCents, 0);
      expect(state.shippingCarrier, ShippingCarrier.none);
      expect(state.weightRange, isNull);
      expect(state.location, isNull);
      expect(state.isLoading, false);
      expect(state.errorKey, isNull);
      expect(state.createdListingId, isNull);
    });
  });

  group('copyWith()', () {
    test('preserves existing values when no params passed', () {
      const state = ListingCreationState(
        step: ListingCreationStep.details,
        imageFiles: [
          SellImage(id: 'a', localPath: 'a.jpg'),
          SellImage(id: 'b', localPath: 'b.jpg'),
        ],
        title: 'Test',
        description: 'Desc',
        categoryL1Id: 'cat1',
        categoryL2Id: 'cat2',
        condition: ListingCondition.good,
        priceInCents: 1500,
        shippingCarrier: ShippingCarrier.postnl,
        weightRange: WeightRange.twoToFive,
        location: '1012AB',
        isLoading: true,
        createdListingId: 'listing-1',
      );

      final copy = state.copyWith();

      expect(copy, equals(state));
      expect(copy.categoryL1Id, 'cat1');
      expect(copy.createdListingId, 'listing-1');
    });

    test('errorKey nullable pattern can set to null', () {
      const state = ListingCreationState(errorKey: 'sell.someError');

      final cleared = state.copyWith(errorKey: () => null);

      expect(cleared.errorKey, isNull);
    });

    test('errorKey nullable pattern can set new value', () {
      final state = ListingCreationState.initial();

      final withError = state.copyWith(errorKey: () => 'sell.newError');

      expect(withError.errorKey, 'sell.newError');
    });

    test('errorKey kept when param omitted', () {
      const state = ListingCreationState(errorKey: 'sell.someError');

      final copy = state.copyWith(title: 'Updated');

      expect(copy.errorKey, 'sell.someError');
      expect(copy.title, 'Updated');
    });
  });

  group('hasUnsavedData', () {
    test('returns false for initial state', () {
      expect(ListingCreationState.initial().hasUnsavedData, false);
    });

    test('returns true when imageFiles is not empty', () {
      final state = ListingCreationState.initial().copyWith(
        imageFiles: const [SellImage(id: 'x', localPath: 'photo.jpg')],
      );
      expect(state.hasUnsavedData, true);
    });

    test('returns true when title is not empty', () {
      final state = ListingCreationState.initial().copyWith(title: 'Chair');
      expect(state.hasUnsavedData, true);
    });

    test('returns true when description is not empty', () {
      final state = ListingCreationState.initial().copyWith(
        description: 'A nice chair',
      );
      expect(state.hasUnsavedData, true);
    });

    test('returns true when categoryL1Id is set', () {
      final state = ListingCreationState.initial().copyWith(
        categoryL1Id: () => 'electronics',
      );
      expect(state.hasUnsavedData, true);
    });

    test('returns true when categoryL2Id is set', () {
      final state = ListingCreationState.initial().copyWith(
        categoryL2Id: () => 'phones',
      );
      expect(state.hasUnsavedData, true);
    });

    test('returns true when condition is set', () {
      final state = ListingCreationState.initial().copyWith(
        condition: () => ListingCondition.likeNew,
      );
      expect(state.hasUnsavedData, true);
    });

    test('returns true when priceInCents is non-zero', () {
      final state = ListingCreationState.initial().copyWith(priceInCents: 100);
      expect(state.hasUnsavedData, true);
    });

    test('returns true when shippingCarrier is not none', () {
      final state = ListingCreationState.initial().copyWith(
        shippingCarrier: ShippingCarrier.dhl,
      );
      expect(state.hasUnsavedData, true);
    });

    test('returns true when weightRange is set', () {
      final state = ListingCreationState.initial().copyWith(
        weightRange: () => WeightRange.zeroToTwo,
      );
      expect(state.hasUnsavedData, true);
    });

    test('returns true when location is set', () {
      final state = ListingCreationState.initial().copyWith(
        location: () => '1012AB',
      );
      expect(state.hasUnsavedData, true);
    });
  });

  group('Equatable', () {
    test('equal states are ==', () {
      final a = ListingCreationState.initial();
      final b = ListingCreationState.initial();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different states are !=', () {
      final a = ListingCreationState.initial();
      final b = a.copyWith(title: 'Different');
      expect(a, isNot(equals(b)));
    });
  });

  group('ShippingCarrier.toDb()', () {
    test('returns correct strings', () {
      expect(ShippingCarrier.postnl.toDb(), 'postnl');
      expect(ShippingCarrier.dhl.toDb(), 'dhl');
      expect(ShippingCarrier.none.toDb(), 'none');
    });
  });

  group('copyWith nullable fields can be cleared', () {
    test('categoryL1Id can be cleared to null', () {
      const state = ListingCreationState(categoryL1Id: 'cat1');
      final cleared = state.copyWith(categoryL1Id: () => null);
      expect(cleared.categoryL1Id, isNull);
    });

    test('condition can be cleared to null', () {
      const state = ListingCreationState(condition: ListingCondition.good);
      final cleared = state.copyWith(condition: () => null);
      expect(cleared.condition, isNull);
    });

    test('weightRange can be cleared to null', () {
      const state = ListingCreationState(weightRange: WeightRange.twoToFive);
      final cleared = state.copyWith(weightRange: () => null);
      expect(cleared.weightRange, isNull);
    });

    test('location can be cleared to null', () {
      const state = ListingCreationState(location: '1012AB');
      final cleared = state.copyWith(location: () => null);
      expect(cleared.location, isNull);
    });

    test('createdListingId can be cleared to null', () {
      const state = ListingCreationState(createdListingId: 'listing-1');
      final cleared = state.copyWith(createdListingId: () => null);
      expect(cleared.createdListingId, isNull);
    });
  });
}
