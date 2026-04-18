import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/core/utils/listing_list_extensions.dart';

ListingEntity _l(String id, {bool fav = false}) => ListingEntity(
  id: id,
  title: 't$id',
  description: 'd',
  priceInCents: 100,
  sellerId: 's',
  sellerName: 'S',
  condition: ListingCondition.good,
  categoryId: 'c',
  imageUrls: const [],
  createdAt: DateTime(2026),
  isFavourited: fav,
);

void main() {
  group('ListingListX.toggleFavourited', () {
    test('flips the matching listing', () {
      final list = [_l('1'), _l('2', fav: true)];
      final out = list.toggleFavourited('1');
      expect(out[0].isFavourited, isTrue);
      expect(out[1].isFavourited, isTrue); // unchanged
    });

    test('returns identical structure when id not found', () {
      final list = [_l('1'), _l('2')];
      final out = list.toggleFavourited('missing');
      expect(out.map((l) => l.isFavourited), [false, false]);
    });
  });

  group('ListingListX.replaceById', () {
    test('replaces the matching listing in place', () {
      final list = [_l('1'), _l('2')];
      final updated = _l('2', fav: true);
      final out = list.replaceById(updated);
      expect(out[0].id, '1');
      expect(identical(out[1], updated), isTrue);
    });

    test('no-op when id not found', () {
      final list = [_l('1')];
      final out = list.replaceById(_l('999'));
      expect(out.length, 1);
      expect(out[0].id, '1');
    });
  });
}
