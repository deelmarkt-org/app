import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';
import 'package:deelmarkt/features/home/domain/repositories/category_repository.dart';

import 'package:deelmarkt/features/home/data/mock/mock_category_data.dart';
import 'package:deelmarkt/features/home/data/mock/mock_l2_category_data.dart';

/// Mock category repository — 8 L1 + 35 L2 categories per design system.
///
/// Data defined in `mock_category_data.dart`.
class MockCategoryRepository implements CategoryRepository {
  @override
  Future<List<CategoryEntity>> getTopLevel() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return l1Categories;
  }

  @override
  Future<CategoryEntity?> getById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final all = [...l1Categories, ...l2Categories];
    return all.where((c) => c.id == id).firstOrNull;
  }

  @override
  Future<List<CategoryEntity>> getSubcategories(String parentId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return l2Categories.where((c) => c.parentId == parentId).toList();
  }
}
