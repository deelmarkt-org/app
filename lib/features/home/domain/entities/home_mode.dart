/// Home screen display mode — buyer or seller.
///
/// Persisted client-side via SharedPreferences (key: `home_mode`).
/// Not stored in the database — this is a UI preference only.
enum HomeMode {
  buyer,
  seller;

  /// Convert to persistence string.
  String toStorage() => name;

  /// Parse from persistence string.
  /// Defaults to [buyer] for unknown values.
  static HomeMode fromStorage(String value) => switch (value) {
    'buyer' => HomeMode.buyer,
    'seller' => HomeMode.seller,
    _ => HomeMode.buyer,
  };
}
