/// Supported shipping carriers — matches DB `shipping_carrier` enum.
enum ShippingCarrier {
  postnl,
  dhl,
  none;

  /// Convert to DB snake_case value.
  String toDb() => name;
}

/// Package weight range for shipping cost calculation.
enum WeightRange {
  zeroToTwo,
  twoToFive,
  fiveToTen,
  tenToTwentyThree,
  twentyThreeToThirtyOne,
}
