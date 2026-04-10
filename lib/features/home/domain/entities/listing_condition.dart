/// Item condition — matches DB `listing_condition` enum.
///
/// DB values: new_with_tags, new_without_tags, like_new, good, fair, poor
/// Display labels are in `core/l10n/*.json` under `condition.*` keys.
/// Use `'condition.${condition.name}'.tr()` in presentation layer.
enum ListingCondition {
  newWithTags,
  newWithoutTags,
  likeNew,
  good,
  fair,
  poor;

  /// Convert to DB snake_case value.
  String toDb() => switch (this) {
    ListingCondition.newWithTags => 'new_with_tags',
    ListingCondition.newWithoutTags => 'new_without_tags',
    ListingCondition.likeNew => 'like_new',
    ListingCondition.good => 'good',
    ListingCondition.fair => 'fair',
    ListingCondition.poor => 'poor',
  };

  /// Parse from DB snake_case value.
  /// Unknown values default to [good] for forward-compatibility
  /// (e.g., if backend adds a new condition before app update).
  static ListingCondition fromDb(String value) => switch (value) {
    'new_with_tags' => ListingCondition.newWithTags,
    'new_without_tags' => ListingCondition.newWithoutTags,
    'like_new' => ListingCondition.likeNew,
    'good' => ListingCondition.good,
    'fair' => ListingCondition.fair,
    'poor' => ListingCondition.poor,
    _ => ListingCondition.good,
  };
}
