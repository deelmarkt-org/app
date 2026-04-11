import 'package:flutter_test/flutter_test.dart';

// Verify the barrel re-export provides all expected types.
// Actual entity logic is tested in
// test/features/home/domain/entities/listing_entity_test.dart.
import 'package:deelmarkt/core/domain/entities/listing_entity.dart';

void main() {
  test('barrel re-exports ListingEntity, ListingStatus, ListingCondition', () {
    // If the barrel doesn't export these, this file won't compile.
    expect(ListingEntity, isNotNull);
    expect(ListingStatus.active, isNotNull);
    expect(ListingCondition.good, isNotNull);
  });
}
