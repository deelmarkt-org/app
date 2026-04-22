import 'package:deelmarkt/core/exceptions/app_exception.dart';

/// Pure retry-delay policy for [PhotoUploadQueue].
///
/// Extracted so the queue file stays under the 150-line ViewModel cap
/// (CLAUDE.md §2.1) and so this pure, deterministic function is trivially
/// unit-testable without touching queue state. See ADR-026.
abstract final class PhotoUploadRetryPolicy {
  /// Minimum delay before retrying a 429-class failure — even when the
  /// server does not send a `retry_after_seconds` hint. Matches R-27 §3.6.
  static const rateLimitFloor = Duration(seconds: 2);

  /// Absolute per-attempt ceiling for rate-limit backoff. Protects the
  /// client from a hostile or buggy backend sending oversized hints
  /// (e.g. `retry_after_seconds: 86400`). 30 s is the industry standard
  /// (GitHub, Stripe, Twilio client SDKs). See ADR-026 §Security.
  static const rateLimitCap = Duration(seconds: 30);

  /// Absolute total-retry budget per job. Prevents runaway retry loops
  /// from consuming battery/network when the server repeatedly hints
  /// delays that individually fit the cap but together exceed a reasonable
  /// user wait.
  static const totalDeadline = Duration(seconds: 60);

  /// Pure, deterministic delay computation.
  ///
  /// Algorithm:
  /// 1. Base delay: exponential + full jitter in `[0, min(base*2^(n-1), cap)]`.
  /// 2. If [lastException] is a [ValidationException] with a non-null
  ///    [ValidationException.retryAfter], derive a rate-limit floor:
  ///    `floor = clamp(retryAfter, rateLimitFloor, rateLimitCap)`.
  /// 3. If the key is `error.image.rate_limited` but no hint was given,
  ///    still apply the static [rateLimitFloor] per R-27 §3.6.
  /// 4. Final delay = `max(jittered, floor)`.
  static Duration computeDelay({
    required int attempt,
    required int randomSeedMs,
    AppException? lastException,
  }) {
    const baseMs = 500;
    const capMs = 8000;
    final exp = baseMs * (1 << (attempt - 1));
    final ceil = exp.clamp(baseMs, capMs);
    // Modulo bias is bounded by `ceil / (1<<30)` — at most ~7.4e-6 for our
    // largest `ceil` (8000 ms). Accepted trade-off for a compact, testable
    // API where `seed < ceil ⇒ delay == seed` (see unit tests). See ADR-026
    // §Observability.
    final jitteredMs = randomSeedMs % ceil;

    final floor = _computeRateLimitFloor(lastException);
    final floorMs = floor?.inMilliseconds ?? 0;

    final delayMs = jitteredMs < floorMs ? floorMs : jitteredMs;
    return Duration(milliseconds: delayMs);
  }

  /// Returns the effective rate-limit floor for [e], or null when no
  /// rate-limit semantics apply. Clamps any server hint to
  /// `[rateLimitFloor, rateLimitCap]` to defuse hostile/buggy hints.
  static Duration? _computeRateLimitFloor(AppException? e) {
    if (e is! ValidationException) return null;
    if (e.messageKey != 'error.image.rate_limited') return null;
    final hint = e.retryAfter;
    if (hint == null) return rateLimitFloor;
    if (hint < rateLimitFloor) return rateLimitFloor;
    if (hint > rateLimitCap) return rateLimitCap;
    return hint;
  }
}
