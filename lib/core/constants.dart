/// App-wide constants — no magic values in code (CLAUDE.md §3.2).
/// Offer-related business rules — shared between domain validation and UI.
abstract final class OfferConstants {
  /// Maximum offer amount: €9,999.99 (999 999 cents).
  /// Prevents absurdly large offers and keeps the value within Mollie's
  /// single-payment limit for marketplace transactions.
  static const int maxOfferCents = 999999;
}

abstract final class AppConstants {
  /// Legal URLs
  static const String termsUrl = 'https://deelmarkt.nl/terms';
  static const String privacyUrl = 'https://deelmarkt.nl/privacy';

  /// Deep link base URL — matches AASA / assetlinks.json host.
  static const String deepLinkBase = 'https://deelmarkt.com';

  /// Allowed hosts for GDPR export and other trusted URLs.
  /// Used for defense-in-depth validation in both data and presentation layers.
  static const Set<String> trustedHosts = {'deelmarkt.nl', 'api.deelmarkt.nl'};

  /// Maximum allowed length for deep-link ID path parameters.
  /// Applies to listing, user, transaction, and shipping routes.
  static const int maxRouteIdLength = 64;
}

/// Quality score thresholds for listing creation (CLAUDE.md §3.2).
///
/// Used by [CalculateQualityScoreUseCase] and [QualityScoreResult].
/// Centralised here so the publish gate and score calculation
/// stay in sync when thresholds are tuned.
abstract final class ListingQualityThresholds {
  /// Minimum number of photos required for a quality pass.
  static const int minPhotos = 3;

  /// Minimum title character count.
  static const int minTitleLength = 10;

  /// Maximum title character count.
  static const int maxTitleLength = 60;

  /// Minimum word count for the description field.
  static const int minDescriptionWords = 50;

  /// Minimum quality score required to publish a listing (0–100).
  static const int publishThreshold = 40;
}
