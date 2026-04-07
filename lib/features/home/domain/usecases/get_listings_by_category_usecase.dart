import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/domain/repositories/category_repository.dart';
import 'package:deelmarkt/features/home/domain/repositories/listing_repository.dart';

/// Fetches listings for a category, expanding L1 categories to their L2 children.
///
/// Per ADR-4: listings carry L2 category IDs. When querying by L1 category,
/// we first resolve its children and search across all child IDs.
class GetListingsByCategoryUseCase {
  const GetListingsByCategoryUseCase(this._listingRepo, this._categoryRepo);

  final ListingRepository _listingRepo;
  final CategoryRepository _categoryRepo;

  /// Returns up to [limit] listings for the given [categoryId].
  ///
  /// If [categoryId] is an L1 category with subcategories, searches across
  /// all L2 children. Otherwise searches the category ID directly.
  Future<List<ListingEntity>> call(String categoryId, {int limit = 6}) async {
    final subcategories = await _categoryRepo.getSubcategories(categoryId);

    final categoryIds =
        subcategories.isEmpty
            ? [categoryId]
            : subcategories.map((c) => c.id).toList();

    // Search each category with graceful error handling per sub-call.
    // If one subcategory search fails, others still contribute results.
    final results = await Future.wait(
      categoryIds.map(
        (id) => _listingRepo
            .search(query: '', categoryId: id, limit: limit)
            .then((r) => r.listings, onError: (_) => <ListingEntity>[]),
      ),
    );

    return results.expand((listings) => listings).take(limit).toList();
  }
}
