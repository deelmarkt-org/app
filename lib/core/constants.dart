/// App-wide constants — no magic values in code (CLAUDE.md §3.2).
abstract final class AppConstants {
  /// Legal URLs
  static const String termsUrl = 'https://deelmarkt.nl/terms';
  static const String privacyUrl = 'https://deelmarkt.nl/privacy';

  /// Deep link base URL — matches AASA / assetlinks.json host.
  static const String deepLinkBase = 'https://deelmarkt.com';

  /// Allowed hosts for GDPR export and other trusted URLs.
  /// Used for defense-in-depth validation in both data and presentation layers.
  static const Set<String> trustedHosts = {'deelmarkt.nl', 'api.deelmarkt.nl'};
}
