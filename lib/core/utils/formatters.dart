/// Shared formatters for price, date, distance.
///
/// Reference: CLAUDE.md §3.2 ("Formatting → core/utils/formatters.dart")
abstract final class Formatters {
  /// Format cents to Euro string with Dutch locale (€45,00).
  ///
  /// Uses comma as decimal separator per Dutch convention.
  static String euroFromCents(int cents) {
    final euros = cents / 100;
    return '\u20AC${euros.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}
