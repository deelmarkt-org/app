import 'dart:math';

import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/review_screen_state.dart';

/// Returns ineligibility l10n key for the given status, or null if eligible.
String? checkReviewEligibility(TransactionStatus status) {
  return switch (status) {
    TransactionStatus.released || TransactionStatus.confirmed => null,
    TransactionStatus.created ||
    TransactionStatus.paymentPending => 'review.error.ineligible.pending',
    TransactionStatus.paid ||
    TransactionStatus.shipped => 'review.error.ineligible.escrowHeld',
    TransactionStatus.delivered => 'review.error.ineligible.delivered',
    TransactionStatus.disputed => 'review.error.ineligible.disputed',
    TransactionStatus.cancelled => 'review.error.ineligible.cancelled',
    _ => 'review.error.ineligible.pending',
  };
}

/// Classifies an exception into a [ReviewErrorClass].
ReviewErrorClass classifyReviewError(Exception e) {
  final message = e.toString().toLowerCase();
  if (message.contains('conflict') || message.contains('409')) {
    return ReviewErrorClass.conflict;
  }
  if (message.contains('rate') || message.contains('429')) {
    return ReviewErrorClass.rateLimit;
  }
  if (message.contains('expired')) return ReviewErrorClass.expired;
  if (message.contains('moderation')) {
    return ReviewErrorClass.moderationBlocked;
  }
  if (message.contains('network') ||
      message.contains('socket') ||
      message.contains('timeout')) {
    return ReviewErrorClass.network;
  }
  return ReviewErrorClass.unknown;
}

/// Trims and strips control/zero-width characters from review body.
String sanitizeReviewBody(String body) {
  return body
      .trim()
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
      .replaceAll(RegExp(r'[\u200B-\u200F\u2028-\u202F\uFEFF]'), '');
}

/// Returns `true` if [body] contains a URL-like pattern.
///
/// Detects `http://`, `https://`, `www.` prefixes and bare domain patterns
/// (e.g. `example.nl/path`). Used to surface [review.urlWarning] in the form.
bool reviewBodyContainsUrl(String body) {
  return RegExp(
    r'https?://|www\.|\b\w+\.(com|nl|be|de|org|net|io|co|app)\b',
    caseSensitive: false,
  ).hasMatch(body);
}

/// Generates a client-side idempotency key.
String generateIdempotencyKey() {
  final now = DateTime.now().microsecondsSinceEpoch;
  final random = Random.secure().nextInt(1 << 32);
  return '$now-$random';
}
