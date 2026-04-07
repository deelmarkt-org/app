import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/models/transaction_status.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/review_helpers.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/review_screen_state.dart';

void main() {
  group('checkReviewEligibility', () {
    test('released returns null (eligible)', () {
      expect(checkReviewEligibility(TransactionStatus.released), isNull);
    });

    test('confirmed returns null (eligible)', () {
      expect(checkReviewEligibility(TransactionStatus.confirmed), isNull);
    });

    test('created returns pending key', () {
      expect(
        checkReviewEligibility(TransactionStatus.created),
        'review.error.ineligible.pending',
      );
    });

    test('paymentPending returns pending key', () {
      expect(
        checkReviewEligibility(TransactionStatus.paymentPending),
        'review.error.ineligible.pending',
      );
    });

    test('paid returns escrowHeld key', () {
      expect(
        checkReviewEligibility(TransactionStatus.paid),
        'review.error.ineligible.escrowHeld',
      );
    });

    test('shipped returns escrowHeld key', () {
      expect(
        checkReviewEligibility(TransactionStatus.shipped),
        'review.error.ineligible.escrowHeld',
      );
    });

    test('delivered returns delivered key', () {
      expect(
        checkReviewEligibility(TransactionStatus.delivered),
        'review.error.ineligible.delivered',
      );
    });

    test('disputed returns disputed key', () {
      expect(
        checkReviewEligibility(TransactionStatus.disputed),
        'review.error.ineligible.disputed',
      );
    });

    test('cancelled returns cancelled key', () {
      expect(
        checkReviewEligibility(TransactionStatus.cancelled),
        'review.error.ineligible.cancelled',
      );
    });
  });

  group('classifyReviewError', () {
    test('message with conflict → ReviewErrorClass.conflict', () {
      expect(
        classifyReviewError(Exception('conflict detected')),
        ReviewErrorClass.conflict,
      );
    });

    test('message with 409 → ReviewErrorClass.conflict', () {
      expect(
        classifyReviewError(Exception('HTTP 409 error')),
        ReviewErrorClass.conflict,
      );
    });

    test('message with rate → ReviewErrorClass.rateLimit', () {
      expect(
        classifyReviewError(Exception('rate limit exceeded')),
        ReviewErrorClass.rateLimit,
      );
    });

    test('message with 429 → ReviewErrorClass.rateLimit', () {
      expect(
        classifyReviewError(Exception('HTTP 429')),
        ReviewErrorClass.rateLimit,
      );
    });

    test('message with expired → ReviewErrorClass.expired', () {
      expect(
        classifyReviewError(Exception('review window expired')),
        ReviewErrorClass.expired,
      );
    });

    test('message with moderation → ReviewErrorClass.moderationBlocked', () {
      expect(
        classifyReviewError(Exception('moderation blocked')),
        ReviewErrorClass.moderationBlocked,
      );
    });

    test('message with network → ReviewErrorClass.network', () {
      expect(
        classifyReviewError(Exception('network unreachable')),
        ReviewErrorClass.network,
      );
    });

    test('message with socket → ReviewErrorClass.network', () {
      expect(
        classifyReviewError(Exception('socket closed')),
        ReviewErrorClass.network,
      );
    });

    test('message with timeout → ReviewErrorClass.network', () {
      expect(
        classifyReviewError(Exception('connection timeout')),
        ReviewErrorClass.network,
      );
    });

    test('unknown message → ReviewErrorClass.unknown', () {
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

    test('strips null byte (\\x00)', () {
      expect(sanitizeReviewBody('abc\x00def'), 'abcdef');
    });

    test('strips control char (\\x07)', () {
      expect(sanitizeReviewBody('abc\x07def'), 'abcdef');
    });

    test('strips zero-width space (\\u200B)', () {
      expect(sanitizeReviewBody('abc\u200Bdef'), 'abcdef');
    });

    test('leaves normal text unchanged', () {
      expect(sanitizeReviewBody('Great seller!'), 'Great seller!');
    });

    test('empty string returns empty', () {
      expect(sanitizeReviewBody(''), '');
    });
  });

  group('generateIdempotencyKey', () {
    test('returns non-empty string', () {
      expect(generateIdempotencyKey(), isNotEmpty);
    });

    test('two successive calls return different keys', () {
      final k1 = generateIdempotencyKey();
      final k2 = generateIdempotencyKey();
      expect(k1, isNot(equals(k2)));
    });

    test('key matches pattern <timestamp>-<random>', () {
      final key = generateIdempotencyKey();
      expect(key, matches(RegExp(r'^\d+-\d+$')));
    });
  });
}
