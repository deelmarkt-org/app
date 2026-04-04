import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';
import 'package:deelmarkt/features/home/domain/repositories/category_repository.dart';

/// Fetches L2 subcategories for a given parent category.
class GetSubcategoriesUseCase {
  const GetSubcategoriesUseCase(this._repo);

  final CategoryRepository _repo;

  /// Returns subcategories for [parentId]. Empty list if none exist.
  Future<List<CategoryEntity>> call(String parentId) =>
      _repo.getSubcategories(parentId);
}
