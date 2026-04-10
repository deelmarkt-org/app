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
      '429 → ValidationException(error.image.rate_limited) with retry_after in debugMessage',
      () {
        final exception = ImageUploadErrorMapper.map(429, const {
          'retry_after_seconds': 120,
        });
        expect(exception, isA<ValidationException>());
        expect(exception.messageKey, 'error.image.rate_limited');
        expect(exception.debugMessage, contains('120'));
      },
    );
  });

  group('ImageUploadErrorMapper.map — transport errors', () {
    test('404 → NetworkException', () {
      final exception = ImageUploadErrorMapper.map(404, null);
      expect(exception, isA<NetworkException>());
    });

    test('502 → NetworkException', () {
      final exception = ImageUploadErrorMapper.map(502, null);
      expect(exception, isA<NetworkException>());
    });

    test('503 → NetworkException', () {
      final exception = ImageUploadErrorMapper.map(503, null);
      expect(exception, isA<NetworkException>());
    });

    test(
      'unexpected status code → NetworkException with status in debugMessage',
      () {
        final exception = ImageUploadErrorMapper.map(599, null);
        expect(exception, isA<NetworkException>());
        expect(exception.debugMessage, contains('599'));
      },
    );
  });
}
