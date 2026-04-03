import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';

/// Pure functions that produce a new [ListingCreationState] from a form update.
///
/// Extracted from [ListingCreationNotifier] to keep the ViewModel under
/// the 150-line limit (CLAUDE.md §2.1). Each function is a pure
/// state→state transform — no side effects, no Riverpod refs.
abstract final class ListingFormUpdaters {
  static ListingCreationState title(ListingCreationState s, String v) =>
      s.copyWith(title: v);

  static ListingCreationState description(ListingCreationState s, String v) =>
      s.copyWith(description: v);

  static ListingCreationState categoryL1(ListingCreationState s, String? id) =>
      s.copyWith(categoryL1Id: () => id, categoryL2Id: () => null);

  static ListingCreationState categoryL2(ListingCreationState s, String? id) =>
      s.copyWith(categoryL2Id: () => id);

  static ListingCreationState condition(
    ListingCreationState s,
    ListingCondition? c,
  ) => s.copyWith(condition: () => c);

  static ListingCreationState price(ListingCreationState s, int cents) =>
      s.copyWith(priceInCents: cents);

  static ListingCreationState shipping(
    ListingCreationState s,
    ShippingCarrier carrier,
    WeightRange? range,
  ) => s.copyWith(shippingCarrier: carrier, weightRange: () => range);

  static ListingCreationState location(
    ListingCreationState s,
    String? postcode,
  ) => s.copyWith(location: () => postcode);
}
