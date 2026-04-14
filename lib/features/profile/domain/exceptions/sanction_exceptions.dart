/// Sealed exception hierarchy for sanction and appeal operations.
///
/// [PostgrestException] mapping is handled in the data layer
/// ([SupabaseSanctionRepository.submitAppeal]) to keep this class pure Dart.
///
/// Reference: docs/epics/E06-trust-moderation.md §Account Suspension & Recovery
/// Reference: supabase/migrations/20260410100000_r37_account_sanctions.sql lines 146–202
sealed class SanctionException implements Exception {
  const SanctionException();

  /// Stable code string used in analytics events (see [SanctionAnalytics]).
  String get code;
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
