import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../dto/category_dto.dart';

/// Supabase implementation of [CategoryRepository].
///
/// Queries the `categories` table. Categories are public read (no auth needed).
/// Reference: CLAUDE.md §1.2, docs/epics/E01-listing-management.md
class SupabaseCategoryRepository implements CategoryRepository {
  const SupabaseCategoryRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CategoryEntity>> getTopLevel() async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .isFilter('parent_id', null)
          .order('sort_order');

      return CategoryDto.fromJsonList(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch categories: ${e.message}');
    }
  }

  @override
  Future<List<CategoryEntity>> getSubcategories(String parentId) async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .eq('parent_id', parentId)
          .order('sort_order');

      return CategoryDto.fromJsonList(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch subcategories: ${e.message}');
    }
  }
}
