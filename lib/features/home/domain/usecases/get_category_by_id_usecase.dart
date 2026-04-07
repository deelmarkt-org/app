import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';
import 'package:deelmarkt/features/home/domain/repositories/category_repository.dart';

/// Fetches a single category by its ID.
class GetCategoryByIdUseCase {
  const GetCategoryByIdUseCase(this._repo);

  final CategoryRepository _repo;

  /// Returns the category or `null` if not found.
  Future<CategoryEntity?> call(String id) => _repo.getById(id);
}
