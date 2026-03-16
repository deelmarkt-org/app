import 'dart:ui';

/// Supported locales and localization configuration.
///
/// DeelMarkt supports Dutch (primary) and English.
/// Reference: docs/epics/E07-infrastructure.md §Localisation
class AppLocales {
  AppLocales._();

  /// Dutch — primary locale (Netherlands)
  static const nl = Locale('nl', 'NL');

  /// English — secondary locale (US)
  static const en = Locale('en', 'US');

  /// All supported locales, ordered by priority.
  static const supportedLocales = [nl, en];

  /// Fallback locale when system locale is not supported.
  static const fallbackLocale = nl;

  /// Path to translation JSON files in assets.
  static const path = 'assets/l10n';
}
