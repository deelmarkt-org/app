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
  /// all L2 children in a single query (avoids N+1). Otherwise searches the
  /// category ID directly.
  Future<List<ListingEntity>> call(String categoryId, {int limit = 6}) async {
    final subcategories = await _categoryRepo.getSubcategories(categoryId);

    final ids =
        subcategories.isEmpty
            ? [categoryId]
            : subcategories.map((c) => c.id).toList();

    // Single query with all category IDs — no N+1.
    final result = await _listingRepo.search(
      query: '',
      categoryIds: ids,
      limit: limit,
    );

    return result.listings;
  }
}
