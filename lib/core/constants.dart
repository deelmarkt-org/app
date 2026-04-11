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

/// Quality score thresholds and weights for listing creation (CLAUDE.md §3.2).
///
/// Used by [CalculateQualityScoreUseCase] and [QualityScoreResult] on the
/// client, and mirrored by the server-side R-26 `listing-quality-score`
/// Edge Function in [supabase/functions/_shared/quality_score_weights.ts].
///
/// **Parity is enforced by [scripts/check_quality_score_parity.sh] in the
/// pre-commit hook.** If you edit the weights or thresholds here, update the
/// TypeScript mirror in the same commit or the hook will reject it.
abstract final class ListingQualityThresholds {
  // ── Thresholds ──────────────────────────────────────────────────────────

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

  // ── Weights (must sum to 100) ───────────────────────────────────────────

  /// Points awarded when ≥[minPhotos] photos are attached.
  static const int photosWeight = 25;

  /// Points awarded when the title length is within
  /// [[minTitleLength], [maxTitleLength]].
  static const int titleWeight = 15;

  /// Points awarded when the description has ≥[minDescriptionWords].
  static const int descriptionWeight = 20;

  /// Points awarded when a non-zero price is set.
  static const int priceWeight = 15;

  /// Points awarded when an L2 category is selected.
  static const int categoryWeight = 15;

  /// Points awarded when a condition is set.
  static const int conditionWeight = 10;
}

/// Star icon size constants used by [StarRow] and rating displays.
///
/// Replaces magic numbers in star rendering (CLAUDE.md §3.3).
abstract final class StarSizes {
  /// Large star size — profile header hero display.
  static const double large = 24;

  /// Small star size — inline cards and review cards.
  static const double small = 14;

  /// Icon size for compact action buttons (e.g. report menu).
  static const double iconCompact = 18;

  /// Minimum touch target for interactive star elements (EAA §10).
  static const double touchTarget = 44;
}
