import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_retry_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhotoUploadRetryPolicy.computeDelay', () {
    test('non-rate-limited failure returns jittered delay under cap', () {
      final delay = PhotoUploadRetryPolicy.computeDelay(
        attempt: 1,
        randomSeedMs: 400,
        lastException: const NetworkException(),
      );
      expect(delay, const Duration(milliseconds: 400));
    });

    test('rate-limit with no hint applies static floor', () {
      final delay = PhotoUploadRetryPolicy.computeDelay(
        attempt: 1,
        randomSeedMs: 100,
        lastException: const ValidationException('error.image.rate_limited'),
      );
      expect(
        delay,
        greaterThanOrEqualTo(PhotoUploadRetryPolicy.rateLimitFloor),
      );
      expect(delay, PhotoUploadRetryPolicy.rateLimitFloor);
    });

    test('rate-limit hint below floor is clamped up to floor', () {
      final delay = PhotoUploadRetryPolicy.computeDelay(
        attempt: 1,
        randomSeedMs: 1,
        lastException: const ValidationException(
          'error.image.rate_limited',
          retryAfter: Duration(milliseconds: 500),
        ),
      );
      expect(delay, PhotoUploadRetryPolicy.rateLimitFloor);
    });

    test('hostile oversized hint is clamped to cap', () {
      final delay = PhotoUploadRetryPolicy.computeDelay(
        attempt: 1,
        randomSeedMs: 1,
        lastException: const ValidationException(
          'error.image.rate_limited',
          retryAfter: Duration(seconds: 86400),
        ),
      );
      expect(delay, PhotoUploadRetryPolicy.rateLimitCap);
    });

    test('reasonable server hint within bounds is honored', () {
      const hint = Duration(seconds: 7);
      final delay = PhotoUploadRetryPolicy.computeDelay(
        attempt: 1,
        randomSeedMs: 1,
        lastException: const ValidationException(
          'error.image.rate_limited',
          retryAfter: hint,
        ),
      );
      expect(delay, hint);
    });

    test('validation failure that is not rate-limited gets no floor', () {
      final delay = PhotoUploadRetryPolicy.computeDelay(
        attempt: 1,
        randomSeedMs: 200,
        lastException: const ValidationException('error.image.invalid_format'),
      );
      expect(delay, const Duration(milliseconds: 200));
    });

    test('jitter window grows exponentially with attempt', () {
      // attempt=4 → exp=500*8=4000 → capped at 8000; seed % 4000 bounded
      final delay = PhotoUploadRetryPolicy.computeDelay(
        attempt: 4,
        randomSeedMs: 3999,
      );
      expect(delay.inMilliseconds, lessThanOrEqualTo(8000));
    });

    test('cap prevents runaway exponential growth', () {
      final delay = PhotoUploadRetryPolicy.computeDelay(
        attempt: 20,
        randomSeedMs: 9999,
      );
      expect(delay.inMilliseconds, lessThanOrEqualTo(8000));
    });

    test('null exception returns pure jittered delay', () {
      final delay = PhotoUploadRetryPolicy.computeDelay(
        attempt: 2,
        randomSeedMs: 250,
      );
      expect(delay, const Duration(milliseconds: 250));
    });
  });

  group('PhotoUploadRetryPolicy constants', () {
    test('floor/cap/deadline invariants', () {
      expect(
        PhotoUploadRetryPolicy.rateLimitFloor,
        lessThan(PhotoUploadRetryPolicy.rateLimitCap),
      );
      expect(
        PhotoUploadRetryPolicy.rateLimitCap,
        lessThanOrEqualTo(PhotoUploadRetryPolicy.totalDeadline),
      );
    });
  });
}
