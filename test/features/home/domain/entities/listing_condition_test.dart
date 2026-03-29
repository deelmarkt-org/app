import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';

void main() {
  group('ListingCondition', () {
    group('toDb', () {
      test('converts all values to snake_case', () {
        expect(ListingCondition.newWithTags.toDb(), 'new_with_tags');
        expect(ListingCondition.newWithoutTags.toDb(), 'new_without_tags');
        expect(ListingCondition.likeNew.toDb(), 'like_new');
        expect(ListingCondition.good.toDb(), 'good');
        expect(ListingCondition.fair.toDb(), 'fair');
        expect(ListingCondition.poor.toDb(), 'poor');
      });
    });

    group('fromDb', () {
      test('parses all valid snake_case values', () {
        expect(
          ListingCondition.fromDb('new_with_tags'),
          ListingCondition.newWithTags,
        );
        expect(
          ListingCondition.fromDb('new_without_tags'),
          ListingCondition.newWithoutTags,
        );
        expect(ListingCondition.fromDb('like_new'), ListingCondition.likeNew);
        expect(ListingCondition.fromDb('good'), ListingCondition.good);
        expect(ListingCondition.fromDb('fair'), ListingCondition.fair);
        expect(ListingCondition.fromDb('poor'), ListingCondition.poor);
      });

      test('throws on unknown value', () {
        expect(() => ListingCondition.fromDb('unknown'), throwsArgumentError);
        expect(() => ListingCondition.fromDb(''), throwsArgumentError);
        expect(() => ListingCondition.fromDb('NEW'), throwsArgumentError);
      });
    });

    group('roundtrip', () {
      test('toDb then fromDb returns same value', () {
        for (final condition in ListingCondition.values) {
          expect(ListingCondition.fromDb(condition.toDb()), condition);
        }
      });
    });
  });
}
