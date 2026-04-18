import 'package:deelmarkt/core/domain/entities/listing_entity.dart';

/// Pure-data helpers for `List<ListingEntity>` used by notifiers that
/// implement optimistic favourite toggles (home, search, category-detail).
extension ListingListX on List<ListingEntity> {
  /// Returns a copy with `isFavourited` flipped on the listing with [id].
  List<ListingEntity> toggleFavourited(String id) => [
    for (final l in this)
      if (l.id == id) l.copyWith(isFavourited: !l.isFavourited) else l,
  ];

  /// Returns a copy with the listing matching `updated.id` replaced.
  List<ListingEntity> replaceById(ListingEntity updated) => [
    for (final l in this)
      if (l.id == updated.id) updated else l,
  ];
}
