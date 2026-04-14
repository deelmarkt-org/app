/// Supported shipping carriers — matches DB `shipping_carrier` enum.
enum ShippingCarrier {
  postnl,
  dhl,
  none;

  /// Convert to DB snake_case value.
  String toDb() => name;
}

/// Package weight range for shipping cost calculation.
///
/// DB values: zero_to_two, two_to_five, five_to_ten,
/// ten_to_twenty_three, twenty_three_to_thirty_one
enum WeightRange {
  zeroToTwo,
  twoToFive,
  fiveToTen,
  tenToTwentyThree,
  twentyThreeToThirtyOne;

  /// Convert to DB snake_case value.
  String toDb() => switch (this) {
    WeightRange.zeroToTwo => 'zero_to_two',
    WeightRange.twoToFive => 'two_to_five',
    WeightRange.fiveToTen => 'five_to_ten',
    WeightRange.tenToTwentyThree => 'ten_to_twenty_three',
    WeightRange.twentyThreeToThirtyOne => 'twenty_three_to_thirty_one',
  };
}
