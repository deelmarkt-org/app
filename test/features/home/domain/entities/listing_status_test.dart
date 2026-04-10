import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/domain/entities/listing_status.dart';

void main() {
  group('ListingStatus', () {
    test('toDb returns correct snake_case values', () {
      expect(ListingStatus.active.toDb(), 'active');
      expect(ListingStatus.sold.toDb(), 'sold');
      expect(ListingStatus.draft.toDb(), 'draft');
    });

    test('fromDb parses known values', () {
      expect(ListingStatus.fromDb('active'), ListingStatus.active);
      expect(ListingStatus.fromDb('sold'), ListingStatus.sold);
      expect(ListingStatus.fromDb('draft'), ListingStatus.draft);
    });

    test('fromDb defaults to active for unknown values', () {
      expect(ListingStatus.fromDb('unknown'), ListingStatus.active);
      expect(ListingStatus.fromDb(''), ListingStatus.active);
    });
  });
}
