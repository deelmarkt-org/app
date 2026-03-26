/// Product category — 8 L1 categories per design system.
///
/// Immutable value object — domain layer, no Flutter/Supabase imports.
///
/// Reference: docs/design-system/components.md §Categories
class CategoryEntity {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.icon,
    this.parentId,
    this.listingCount = 0,
  });

  final String id;
  final String name;

  /// Phosphor icon name (e.g. 'car', 'device-mobile').
  final String icon;

  /// Null for L1 categories, parent ID for L2 subcategories.
  final String? parentId;

  final int listingCount;

  /// Whether this is a top-level (L1) category.
  bool get isTopLevel => parentId == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CategoryEntity && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
