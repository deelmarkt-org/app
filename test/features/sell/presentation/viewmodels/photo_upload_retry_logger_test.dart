import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_retry_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('photo_upload_retry_logger', () {
    test('logRetry does not throw for a rate-limited ValidationException', () {
      expect(
        () => logRetry(
          photoId: 'photo-abc',
          attempt: 2,
          maxAttempts: 3,
          delay: const Duration(seconds: 2),
          exception: const ValidationException(
            'error.image.rate_limited',
            retryAfter: Duration(seconds: 2),
          ),
        ),
        returnsNormally,
      );
    });

    test('logRetry does not throw for non-rate-limited exceptions', () {
      expect(
        () => logRetry(
          photoId: 'photo-xyz',
          attempt: 1,
          maxAttempts: 3,
          delay: const Duration(milliseconds: 500),
          exception: const NetworkException(),
        ),
        returnsNormally,
      );
    });

    test(
      'logRetry does not throw for validation failures that are not 429',
      () {
        expect(
          () => logRetry(
            photoId: 'photo-123',
            attempt: 1,
            maxAttempts: 3,
            delay: const Duration(milliseconds: 250),
            exception: const ValidationException('error.image.invalid_format'),
          ),
          returnsNormally,
        );
      },
    );

    test('logRetryBudgetExhausted does not throw', () {
      expect(
        () => logRetryBudgetExhausted(
          photoId: 'photo-def',
          attempt: 3,
          maxAttempts: 3,
          totalDeadline: const Duration(seconds: 60),
          exception: const ValidationException(
            'error.image.rate_limited',
            retryAfter: Duration(seconds: 30),
          ),
        ),
        returnsNormally,
      );
    });

    test('logRetry handles zero-duration delays', () {
      expect(
        () => logRetry(
          photoId: 'photo-0',
          attempt: 1,
          maxAttempts: 3,
          delay: Duration.zero,
          exception: const NetworkException(),
        ),
        returnsNormally,
      );
    });
  });
}
