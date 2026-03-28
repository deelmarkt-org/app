import '../entities/category_entity.dart';

/// Category repository interface — domain layer.
abstract class CategoryRepository {
  /// Get all top-level (L1) categories.
  Future<List<CategoryEntity>> getTopLevel();

  /// Get subcategories (L2) for a parent category.
  Future<List<CategoryEntity>> getSubcategories(String parentId);
}
