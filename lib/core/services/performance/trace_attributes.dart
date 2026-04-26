import 'package:flutter/foundation.dart';

/// Allowlisted trace attribute keys + bucketing helpers.
///
/// Trace attributes are queryable plaintext in Firebase / Sentry consoles
/// and exported to BigQuery. Treat them as a public log surface for
/// GDPR Art. 5(1)(c) (data minimisation). High-cardinality values must be
/// bucketed; PII is forbidden.
///
/// Reference: `docs/PLAN-P56-firebase-performance-traces.md` §3.4 + ADR-027.
abstract final class TraceAttributes {
  /// Locale tag (`nl` / `en`).
  static const String locale = 'locale';

  /// Platform (`ios` / `android` / `web`).
  static const String platform = 'platform';

  /// Network type (`wifi` / `cellular` / `none`).
  static const String networkType = 'network_type';

  /// Cache-hit boolean (`true` / `false`).
  static const String cacheHit = 'cache_hit';

  /// Bucketed result count (use [bucketResultCount]).
  static const String resultCount = 'result_count';

  /// Bucketed image size (use [bucketImageSize]).
  static const String imageSizeBucket = 'image_size_bucket';

  /// Payment method (`ideal` / `card` / etc.).
  static const String paymentMethod = 'payment_method';

  /// Listing category (low cardinality — categories are L1).
  static const String listingCategory = 'listing_category';

  /// Bucketed listing price (use [bucketPriceCents]).
  static const String listingPriceBucket = 'listing_price_bucket';

  /// Allowlist of all permitted attribute keys.
  ///
  /// Calls to [validateKey] check against this set.
  static const Set<String> allowlist = {
    locale,
    platform,
    networkType,
    cacheHit,
    resultCount,
    imageSizeBucket,
    paymentMethod,
    listingCategory,
    listingPriceBucket,
  };

  /// Maximum permitted length for an attribute value.
  ///
  /// Firebase Performance silently truncates values >100 chars; Sentry tags
  /// truncate at >200. Picking 100 ensures parity across both backends.
  /// Per security review PR #220 finding **H-1**.
  static const int maxValueLength = 100;

  /// Validate that [key] is on the allowlist.
  ///
  /// In debug builds, throws [ArgumentError] for forbidden keys (catch PII
  /// regressions early). In release builds, returns `false` so callers can
  /// drop the attribute silently — never expose unintended PII.
  static bool validateKey(String key) {
    if (allowlist.contains(key)) return true;
    if (kDebugMode) {
      throw ArgumentError.value(
        key,
        'attribute key',
        'Attribute is not on the trace allowlist. See TraceAttributes for the '
            'permitted keys; PII (user_id, email, listing_id, search_term, '
            'coordinates, device_id, ip) is forbidden.',
      );
    }
    return false;
  }

  /// Validate that [value] is safe to send to Firebase / Sentry.
  ///
  /// Two rules, both enforced:
  ///
  /// 1. **Length** — values >[maxValueLength] characters are silently
  ///    truncated by Firebase (data integrity bug — observability becomes
  ///    unreliable when arbitrary callers, e.g. localised category names,
  ///    accidentally exceed the limit). Per security review **H-1**.
  ///
  /// 2. **Control characters** — `\r`, `\n`, `\t`, NUL, or any C0/C1 control
  ///    char must be rejected. Sentry tags propagate to Discover queries,
  ///    alerts, and BigQuery exports; injected newlines can pollute downstream
  ///    log shippers. Per security review **H-2**.
  ///
  /// Returns `true` if the value passes both checks. In debug builds, throws
  /// [ArgumentError] for failing values to surface bugs early; in release
  /// builds, returns `false` so callers can drop the attribute silently.
  static bool validateValue(String value) {
    if (value.length > maxValueLength) {
      if (kDebugMode) {
        throw ArgumentError.value(
          value,
          'attribute value',
          'Attribute value exceeds $maxValueLength chars '
              '(${value.length}); Firebase will silently truncate. '
              'Bucket high-cardinality values per TraceAttributes helpers.',
        );
      }
      return false;
    }
    if (_controlChars.hasMatch(value)) {
      if (kDebugMode) {
        throw ArgumentError.value(
          value,
          'attribute value',
          'Attribute value contains control characters (\\r/\\n/\\t/NUL/etc); '
              'rejected to prevent log injection into Sentry Discover + '
              'downstream log shippers.',
        );
      }
      return false;
    }
    return true;
  }

  /// Matches any C0 / C1 control character (excludes printable ASCII + extended).
  ///
  /// `\x00-\x1F` covers NUL through Unit Separator (incl. \t \n \r);
  /// `\x7F` is DEL; `\x80-\x9F` is the C1 control range.
  static final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F-\x9F]');

  /// Bucket a result count into a low-cardinality string.
  static String bucketResultCount(int n) {
    if (n <= 0) return '0';
    if (n <= 10) return '1-10';
    if (n <= 50) return '11-50';
    return '50+';
  }

  /// Bucket an image size in bytes.
  static String bucketImageSize(int bytes) {
    if (bytes < 200 * 1024) return '<200kb';
    if (bytes < 1024 * 1024) return '200kb-1mb';
    return '>1mb';
  }

  /// Bucket a price in cents (€).
  static String bucketPriceCents(int cents) {
    if (cents < 5000) return '0-50';
    if (cents < 20000) return '50-200';
    if (cents < 100000) return '200-1000';
    return '1000+';
  }
}
