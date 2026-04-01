import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';
import 'package:deelmarkt/features/home/domain/repositories/category_repository.dart';

/// Fetches top-level (L1) categories for the home screen carousel.
class GetTopCategoriesUseCase {
  const GetTopCategoriesUseCase(this._repo);

  final CategoryRepository _repo;

  /// Returns all L1 categories.
  Future<List<CategoryEntity>> call() => _repo.getTopLevel();
}
