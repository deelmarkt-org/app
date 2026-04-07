import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/review_helpers.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/review_screen_state.dart';

void main() {
  group('checkReviewEligibility', () {
    test('returns null for released (eligible)', () {
      expect(checkReviewEligibility(TransactionStatus.released), isNull);
    });

    test('returns null for confirmed (eligible)', () {
      expect(checkReviewEligibility(TransactionStatus.confirmed), isNull);
    });

    test('returns pending key for created', () {
      expect(
        checkReviewEligibility(TransactionStatus.created),
        'review.error.ineligible.pending',
      );
    });

    test('returns pending key for paymentPending', () {
      expect(
        checkReviewEligibility(TransactionStatus.paymentPending),
        'review.error.ineligible.pending',
      );
    });

    test('returns escrowHeld key for paid', () {
      expect(
        checkReviewEligibility(TransactionStatus.paid),
        'review.error.ineligible.escrowHeld',
      );
    });

    test('returns escrowHeld key for shipped', () {
      expect(
        checkReviewEligibility(TransactionStatus.shipped),
        'review.error.ineligible.escrowHeld',
      );
    });

    test('returns delivered key for delivered', () {
      expect(
        checkReviewEligibility(TransactionStatus.delivered),
        'review.error.ineligible.delivered',
      );
    });

    test('returns disputed key for disputed', () {
      expect(
        checkReviewEligibility(TransactionStatus.disputed),
        'review.error.ineligible.disputed',
      );
    });

    test('returns cancelled key for cancelled', () {
      expect(
        checkReviewEligibility(TransactionStatus.cancelled),
        'review.error.ineligible.cancelled',
      );
    });

    test('returns pending key for expired (wildcard)', () {
      expect(
        checkReviewEligibility(TransactionStatus.expired),
        'review.error.ineligible.pending',
      );
    });
  });

  group('classifyReviewError', () {
    test('returns conflict for conflict message', () {
      expect(
        classifyReviewError(Exception('conflict detected')),
        ReviewErrorClass.conflict,
      );
    });

    test('returns conflict for 409 status code', () {
      expect(
        classifyReviewError(Exception('409 too many')),
        ReviewErrorClass.conflict,
      );
    });

    test('returns rateLimit for rate message', () {
      expect(
        classifyReviewError(Exception('rate limit exceeded')),
        ReviewErrorClass.rateLimit,
      );
    });

    test('returns rateLimit for 429 status code', () {
      expect(
        classifyReviewError(Exception('http 429')),
        ReviewErrorClass.rateLimit,
      );
    });

    test('returns expired for expired message', () {
      expect(
        classifyReviewError(Exception('token expired')),
        ReviewErrorClass.expired,
      );
    });

    test('returns moderationBlocked for moderation message', () {
      expect(
        classifyReviewError(Exception('moderation blocked content')),
        ReviewErrorClass.moderationBlocked,
      );
    });

    test('returns network for network message', () {
      expect(
        classifyReviewError(Exception('network error')),
        ReviewErrorClass.network,
      );
    });

    test('returns network for socket error', () {
      expect(
        classifyReviewError(Exception('socket connection failed')),
        ReviewErrorClass.network,
      );
    });

    test('returns network for timeout', () {
      expect(
        classifyReviewError(Exception('connection timeout')),
        ReviewErrorClass.network,
      );
    });

    test('returns unknown for unrecognised message', () {
      expect(
        classifyReviewError(Exception('something went wrong')),
        ReviewErrorClass.unknown,
      );
    });
  });

  group('sanitizeReviewBody', () {
    test('trims leading and trailing whitespace', () {
      expect(sanitizeReviewBody('  hello  '), 'hello');
    });

    test('strips null control characters', () {
      expect(sanitizeReviewBody('hello\x00world'), 'helloworld');
    });

    test('strips other control characters', () {
      expect(sanitizeReviewBody('hello\x08world'), 'helloworld');
    });

    test('strips zero-width space', () {
      expect(sanitizeReviewBody('hello\u200Bworld'), 'helloworld');
    });

    test('strips BOM character', () {
      expect(sanitizeReviewBody('hello\uFEFFworld'), 'helloworld');
    });

    test('preserves normal text unchanged', () {
      expect(sanitizeReviewBody('Geweldige verkoper!'), 'Geweldige verkoper!');
    });

    test('handles empty string', () {
      expect(sanitizeReviewBody(''), '');
    });

    test('handles whitespace-only string', () {
      expect(sanitizeReviewBody('   '), '');
    });
  });

  group('reviewBodyContainsUrl', () {
    test('detects https:// URLs', () {
      expect(reviewBodyContainsUrl('See https://scam.nl'), isTrue);
    });

    test('detects http:// URLs', () {
      expect(reviewBodyContainsUrl('Visit http://example.com now'), isTrue);
    });

    test('detects www. prefix', () {
      expect(reviewBodyContainsUrl('Go to www.example.com'), isTrue);
    });

    test('detects bare domain patterns', () {
      expect(reviewBodyContainsUrl('Check out example.nl/item'), isTrue);
    });

    test('returns false for clean text', () {
      expect(reviewBodyContainsUrl('Great seller, fast delivery!'), isFalse);
    });

    test('returns false for empty string', () {
      expect(reviewBodyContainsUrl(''), isFalse);
    });
  });

  group('generateIdempotencyKey', () {
    test('generates a non-empty string', () {
      expect(generateIdempotencyKey(), isNotEmpty);
    });

    test('generates unique keys on each call', () {
      final key1 = generateIdempotencyKey();
      final key2 = generateIdempotencyKey();
      expect(key1, isNot(key2));
    });

    test('key contains the dash separator', () {
      final key = generateIdempotencyKey();
      expect(key, contains('-'));
    });
  });
}
