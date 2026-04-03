import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';

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
        imageFiles: ['a.jpg', 'b.jpg'],
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
        imageFiles: ['photo.jpg'],
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
        categoryL1Id: 'electronics',
      );
      expect(state.hasUnsavedData, true);
    });

    test('returns true when categoryL2Id is set', () {
      final state = ListingCreationState.initial().copyWith(
        categoryL2Id: 'phones',
      );
      expect(state.hasUnsavedData, true);
    });

    test('returns true when condition is set', () {
      final state = ListingCreationState.initial().copyWith(
        condition: ListingCondition.likeNew,
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
        weightRange: WeightRange.zeroToTwo,
      );
      expect(state.hasUnsavedData, true);
    });

    test('returns true when location is set', () {
      final state = ListingCreationState.initial().copyWith(location: '1012AB');
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

  group('WeightRange.label', () {
    test('returns correct Dutch labels', () {
      expect(WeightRange.zeroToTwo.label, '0-2 kg');
      expect(WeightRange.twoToFive.label, '2-5 kg');
      expect(WeightRange.fiveToTen.label, '5-10 kg');
      expect(WeightRange.tenToTwentyThree.label, '10-23 kg');
      expect(WeightRange.twentyThreeToThirtyOne.label, '23-31 kg');
    });
  });
}
