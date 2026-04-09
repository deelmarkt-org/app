/// Listing publication status — matches DB `listing_status` enum.
///
/// DB values: active, sold, draft
enum ListingStatus {
  active,
  sold,
  draft;

  /// Convert to DB snake_case value.
  String toDb() => name;

  /// Parse from DB value.
  /// Unknown values default to [active] for forward-compatibility.
  static ListingStatus fromDb(String value) => switch (value) {
    'active' => ListingStatus.active,
    'sold' => ListingStatus.sold,
    'draft' => ListingStatus.draft,
    _ => ListingStatus.active,
  };
}
