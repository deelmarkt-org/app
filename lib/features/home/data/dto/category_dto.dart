import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';

/// DTO for converting Supabase REST JSON to [CategoryEntity].
class CategoryDto {
  const CategoryDto._();

  /// Parse a Supabase JSON row from `categories` table.
  static CategoryEntity fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final icon = json['icon'];

    if (id is! String || icon is! String) {
      throw FormatException(
        'CategoryDto.fromJson: missing required fields (id=$id, icon=$icon)',
      );
    }

    return CategoryEntity(
      id: id,
      // Use Dutch name as primary (NL marketplace), fall back to English
      name: (json['name_nl'] as String?) ?? (name is String ? name : id),
      icon: icon,
      parentId: json['parent_id'] as String?,
      listingCount: (json['listing_count'] as int?) ?? 0,
    );
  }

  /// Parse a list of JSON rows. Skips malformed entries.
  static List<CategoryEntity> fromJsonList(List<dynamic> jsonList) {
    return jsonList.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }
}
