import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';

/// Category repository interface — domain layer.
abstract class CategoryRepository {
  /// Get all top-level (L1) categories.
  Future<List<CategoryEntity>> getTopLevel();

  /// Get a single category by ID. Returns `null` if not found.
  Future<CategoryEntity?> getById(String id);

  /// Get subcategories (L2) for a parent category.
  Future<List<CategoryEntity>> getSubcategories(String parentId);
}
