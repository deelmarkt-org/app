import '../../domain/entities/category_entity.dart';

/// DTO for converting Supabase REST JSON to [CategoryEntity].
class CategoryDto {
  const CategoryDto._();

  /// Parse a Supabase JSON row from `categories` table.
  static CategoryEntity fromJson(Map<String, dynamic> json) {
    return CategoryEntity(
      id: json['id'] as String,
      // Use Dutch name as primary (NL marketplace), fall back to English
      name: (json['name_nl'] as String?) ?? json['name'] as String,
      icon: json['icon'] as String,
      parentId: json['parent_id'] as String?,
      listingCount: (json['listing_count'] as int?) ?? 0,
    );
  }

  /// Parse a list of JSON rows.
  static List<CategoryEntity> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }
}
