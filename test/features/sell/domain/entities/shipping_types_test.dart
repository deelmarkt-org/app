import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/sell/domain/entities/shipping_types.dart';

void main() {
  group('ShippingCarrier', () {
    test('toDb returns enum name', () {
      expect(ShippingCarrier.postnl.toDb(), 'postnl');
      expect(ShippingCarrier.dhl.toDb(), 'dhl');
      expect(ShippingCarrier.none.toDb(), 'none');
    });
  });

  group('WeightRange', () {
    test('toDb converts camelCase to snake_case', () {
      expect(WeightRange.zeroToTwo.toDb(), 'zero_to_two');
      expect(WeightRange.twoToFive.toDb(), 'two_to_five');
      expect(WeightRange.fiveToTen.toDb(), 'five_to_ten');
      expect(WeightRange.tenToTwentyThree.toDb(), 'ten_to_twenty_three');
      expect(
        WeightRange.twentyThreeToThirtyOne.toDb(),
        'twenty_three_to_thirty_one',
      );
    });

    test('all values produce valid DB strings', () {
      for (final range in WeightRange.values) {
        expect(range.toDb(), isNotEmpty);
        expect(range.toDb(), matches(RegExp(r'^[a-z_]+$')));
      }
    });
  });
}
