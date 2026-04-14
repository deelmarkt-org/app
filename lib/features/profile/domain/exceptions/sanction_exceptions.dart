import 'package:supabase_flutter/supabase_flutter.dart';

/// Sealed exception hierarchy for sanction and appeal operations.
///
/// Use [SanctionException.fromPostgrestError] to convert [PostgrestException]
/// instances from the [submit_appeal] / [get_active_sanction] RPCs.
///
/// Reference: docs/epics/E06-trust-moderation.md §Account Suspension & Recovery
/// Reference: supabase/migrations/20260410100000_r37_account_sanctions.sql lines 146–202
sealed class SanctionException implements Exception {
  const SanctionException();

  /// Stable code string used in analytics events (see [SanctionAnalytics]).
  String get code;

  /// Maps a [PostgrestException] from the sanction RPCs to the correct subclass.
  ///
  /// Mapping rules:
  /// - Message contains "14 days" / "14-day" → [AppealWindowExpired]
  /// - Message contains "final decision" / "counter-appeal" → [AppealAlreadyResolved]
  /// - [PostgrestException.code] is "PGRST116" (no rows) → [SanctionNotFound]
  /// - HTTP status 429 or message contains "rate" → [AppealRateLimited]
  /// - Everything else → [UnknownSanctionError]
  static SanctionException fromPostgrestError(PostgrestException e) {
    final msg = e.message.toLowerCase();

    if (msg.contains('14 day') || msg.contains('14-day')) {
      return const AppealWindowExpired();
    }
    if (msg.contains('final decision') || msg.contains('counter-appeal')) {
      return const AppealAlreadyResolved();
    }
    if (e.code == 'PGRST116') {
      return const SanctionNotFound();
    }
    if ((e.details?.toString().contains('429') ?? false) ||
        msg.contains('rate')) {
      return const AppealRateLimited();
    }
    return UnknownSanctionError(e.message);
  }
}

/// The 14-day window in which an appeal may be submitted has closed.
final class AppealWindowExpired extends SanctionException {
  const AppealWindowExpired();

  @override
  String get code => 'APPEAL_WINDOW_EXPIRED';

  @override
  String toString() =>
      'AppealWindowExpired: the 14-day appeal window has closed.';
}

/// A moderator has already issued a final decision on this appeal.
final class AppealAlreadyResolved extends SanctionException {
  const AppealAlreadyResolved();

  @override
  String get code => 'APPEAL_ALREADY_RESOLVED';

  @override
  String toString() =>
      'AppealAlreadyResolved: a final decision has already been made.';
}

/// No sanction was found for the given ID (PGRST116 — no rows returned).
final class SanctionNotFound extends SanctionException {
  const SanctionNotFound();

  @override
  String get code => 'SANCTION_NOT_FOUND';

  @override
  String toString() => 'SanctionNotFound: no matching sanction record exists.';
}

/// The server rate-limited the appeal submission (HTTP 429-class).
final class AppealRateLimited extends SanctionException {
  const AppealRateLimited();

  @override
  String get code => 'APPEAL_RATE_LIMITED';

  @override
  String toString() =>
      'AppealRateLimited: too many appeal submissions — please try again later.';
}

/// Unrecoverable transport or network failure.
final class NetworkFailure extends SanctionException {
  const NetworkFailure([this.message = '']);

  final String message;

  @override
  String get code => 'NETWORK_FAILURE';

  @override
  String toString() => 'NetworkFailure: $message';
}

/// Catch-all for server errors not covered by the above subclasses.
final class UnknownSanctionError extends SanctionException {
  const UnknownSanctionError(this.message);

  final String message;

  @override
  String get code => 'UNKNOWN_SANCTION_ERROR';

  @override
  String toString() => 'UnknownSanctionError: $message';
}
