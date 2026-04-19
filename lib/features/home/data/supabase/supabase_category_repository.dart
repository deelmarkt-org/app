import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';
import 'package:deelmarkt/features/home/domain/repositories/category_repository.dart';
import 'package:deelmarkt/features/home/data/dto/category_dto.dart';

/// Supabase implementation of [CategoryRepository].
///
/// Queries the `categories` table. Categories are public read (no auth needed).
/// Reference: CLAUDE.md §1.2, docs/epics/E01-listing-management.md
class SupabaseCategoryRepository implements CategoryRepository {
  const SupabaseCategoryRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'categories';
  static const _colParentId = 'parent_id';
  static const _colSortOrder = 'sort_order';

  @override
  Future<List<CategoryEntity>> getTopLevel() async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .isFilter(_colParentId, null)
          .order(_colSortOrder);

      return CategoryDto.fromJsonList(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch categories: ${e.message}');
    }
  }

  @override
  Future<CategoryEntity?> getById(String id) async {
    try {
      final response =
          await _client.from(_table).select().eq('id', id).maybeSingle();
      if (response == null) return null;
      return CategoryDto.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch category: ${e.message}');
    }
  }

  @override
  Future<List<CategoryEntity>> getSubcategories(String parentId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq(_colParentId, parentId)
          .order(_colSortOrder);

      return CategoryDto.fromJsonList(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch subcategories: ${e.message}');
    }
  }
}
