import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/sell/data/services/image_upload_error_mapper.dart';

void main() {
  group('ImageUploadErrorMapper.map — auth errors', () {
    test('401 → AuthException(error.auth.unauthenticated)', () {
      final exception = ImageUploadErrorMapper.map(401, null);
      expect(exception, isA<AuthException>());
      expect(exception.messageKey, 'error.auth.unauthenticated');
    });

    test('403 → AuthException(error.image.ownership_mismatch)', () {
      final exception = ImageUploadErrorMapper.map(403, null);
      expect(exception, isA<AuthException>());
      expect(exception.messageKey, 'error.image.ownership_mismatch');
    });
  });

  group('ImageUploadErrorMapper.map — validation errors', () {
    test('413 → ValidationException(error.image.too_large)', () {
      final exception = ImageUploadErrorMapper.map(413, null);
      expect(exception, isA<ValidationException>());
      expect(exception.messageKey, 'error.image.too_large');
    });

    test(
      '422 → ValidationException(error.image.blocked) and threat in debugMessage',
      () {
        final exception = ImageUploadErrorMapper.map(422, const {
          'error': 'Image blocked: virus: Eicar-Test',
        });
        expect(exception, isA<ValidationException>());
        expect(exception.messageKey, 'error.image.blocked');
        expect(exception.debugMessage, contains('Eicar-Test'));
      },
    );

    test('422 with non-map body still maps to error.image.blocked', () {
      final exception = ImageUploadErrorMapper.map(422, 'unstructured');
      expect(exception, isA<ValidationException>());
      expect(exception.messageKey, 'error.image.blocked');
    });

    test(
      '429 → ValidationException(error.image.rate_limited) with typed retryAfter',
      () {
        final exception = ImageUploadErrorMapper.map(429, const {
          'retry_after_seconds': 120,
        });
        expect(exception, isA<ValidationException>());
        expect(exception.messageKey, 'error.image.rate_limited');
        expect(
          (exception as ValidationException).retryAfter,
          const Duration(seconds: 120),
        );
        expect(exception.debugMessage, contains('120'));
      },
    );

    test('429 w/o body → ValidationException with retryAfter == null', () {
      final exception = ImageUploadErrorMapper.map(429, null);
      expect(exception, isA<ValidationException>());
      expect((exception as ValidationException).retryAfter, isNull);
    });

    test(
      '429 with malformed body (string instead of map) → retryAfter == null',
      () {
        final exception = ImageUploadErrorMapper.map(429, 'totally-wrong');
        expect((exception as ValidationException).retryAfter, isNull);
      },
    );

    test(
      '429 with negative retry_after_seconds → retryAfter == null (defensive)',
      () {
        final exception = ImageUploadErrorMapper.map(429, const {
          'retry_after_seconds': -5,
        });
        expect((exception as ValidationException).retryAfter, isNull);
      },
    );

    test('429 with non-numeric retry_after_seconds → retryAfter == null', () {
      final exception = ImageUploadErrorMapper.map(429, const {
        'retry_after_seconds': 'soon',
      });
      expect((exception as ValidationException).retryAfter, isNull);
    });

    test('429 with string retry_after_seconds is parsed into Duration', () {
      final exception = ImageUploadErrorMapper.map(429, const {
        'retry_after_seconds': '45',
      });
      expect(
        (exception as ValidationException).retryAfter,
        const Duration(seconds: 45),
      );
    });
  });

  group('ImageUploadErrorMapper.map — transport errors', () {
    // These cases carry dedicated l10n keys so users don't see a
    // misleading "No internet connection" message when the actual
    // failure is an upstream outage (Cloudinary, Cloudmersive, etc).

    test('404 → NetworkException(error.image.not_found)', () {
      final exception = ImageUploadErrorMapper.map(404, null);
      expect(exception, isA<NetworkException>());
      expect(exception.messageKey, 'error.image.not_found');
    });

    test('500 → NetworkException(error.image.upload_failed)', () {
      final exception = ImageUploadErrorMapper.map(500, null);
      expect(exception, isA<NetworkException>());
      expect(exception.messageKey, 'error.image.upload_failed');
    });

    test('502 → NetworkException(error.image.upload_failed)', () {
      // Cloudinary outage: EF returns 502 after its fetch() to
      // api.cloudinary.com fails. User sees "Image upload failed".
      final exception = ImageUploadErrorMapper.map(502, null);
      expect(exception, isA<NetworkException>());
      expect(exception.messageKey, 'error.image.upload_failed');
    });

    test('503 → NetworkException(error.image.scan_unavailable)', () {
      // Cloudmersive outage: EF returns 503 from its fail-closed
      // branch. User sees "Our safety check is temporarily
      // unavailable" instead of the misleading "No internet".
      final exception = ImageUploadErrorMapper.map(503, null);
      expect(exception, isA<NetworkException>());
      expect(exception.messageKey, 'error.image.scan_unavailable');
    });

    test(
      'unexpected status code → NetworkException(error.network) with status in debugMessage',
      () {
        final exception = ImageUploadErrorMapper.map(599, null);
        expect(exception, isA<NetworkException>());
        expect(exception.messageKey, 'error.network');
        expect(exception.debugMessage, contains('599'));
      },
    );
  });
}
