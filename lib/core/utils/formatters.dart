import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Shared formatters for price, date, distance.
///
/// Reference: CLAUDE.md §3.2 ("Formatting → core/utils/formatters.dart")
abstract final class Formatters {
  static bool _dateLocalesInitialized = false;

  /// Format cents to Euro string with Dutch locale (€45,00).
  ///
  /// Uses comma as decimal separator per Dutch convention.
  static String euroFromCents(int cents) {
    final euros = cents / 100;
    return '\u20AC${euros.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// Initialize date locale data. Safe to call multiple times.
  static Future<void> initDateLocales() async {
    if (_dateLocalesInitialized) return;
    await initializeDateFormatting('nl');
    await initializeDateFormatting('en');
    _dateLocalesInitialized = true;
  }

  /// Format a DateTime as a short date + time string.
  ///
  /// NL: "25 mrt. 2026 18:00"
  /// EN: "25 Mar 2026 18:00"
  ///
  /// Uses `intl` DateFormat for proper locale-aware formatting.
  /// Call [initDateLocales] once at app startup before using this.
  static String shortDateTime(DateTime dt, {String locale = 'nl'}) {
    try {
      final format = DateFormat('d MMM y HH:mm', locale);
      return format.format(dt);
    } catch (_) {
      // Fallback if locale data not initialized (e.g. in tests)
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.day}/${dt.month}/${dt.year} $h:$m';
    }
  }
}
