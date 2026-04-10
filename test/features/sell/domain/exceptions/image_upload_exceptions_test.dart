import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/sell/domain/exceptions/image_upload_exceptions.dart';

void main() {
  group('ImageUploadNetworkException', () {
    test('has errorKey sell.uploadErrorNetwork', () {
      const e = ImageUploadNetworkException();
      expect(e.errorKey, equals('sell.uploadErrorNetwork'));
    });

    test('isRetryable is true', () {
      const e = ImageUploadNetworkException();
      expect(e.isRetryable, isTrue);
    });

    test('shouldReport is true', () {
      const e = ImageUploadNetworkException();
      expect(e.shouldReport, isTrue);
    });

    test('carries optional cause', () {
      final cause = Exception('DNS lookup failed');
      final e = ImageUploadNetworkException(cause: cause);
      expect(e.cause, same(cause));
    });

    test('toString includes errorKey', () {
      const e = ImageUploadNetworkException();
      expect(e.toString(), contains('sell.uploadErrorNetwork'));
    });

    test('is a subtype of ImageUploadException', () {
      const e = ImageUploadNetworkException();
      expect(e, isA<ImageUploadException>());
      expect(e, isA<Exception>());
    });
  });

  group('ImageUploadServerException', () {
    test('has errorKey sell.uploadErrorNetwork', () {
      const e = ImageUploadServerException(statusCode: 500);
      expect(e.errorKey, equals('sell.uploadErrorNetwork'));
    });

    test('isRetryable is true', () {
      const e = ImageUploadServerException(statusCode: 500);
      expect(e.isRetryable, isTrue);
    });

    test('shouldReport is true', () {
      const e = ImageUploadServerException(statusCode: 502);
      expect(e.shouldReport, isTrue);
    });

    test('exposes status code and details', () {
      const e = ImageUploadServerException(
        statusCode: 503,
        details: 'service unavailable',
      );
      expect(e.statusCode, equals(503));
      expect(e.details, equals('service unavailable'));
    });

    test('details defaults to null', () {
      const e = ImageUploadServerException(statusCode: 500);
      expect(e.details, isNull);
    });
  });

  group('ImageUploadAuthException', () {
    test('has errorKey sell.uploadErrorAuth', () {
      const e = ImageUploadAuthException();
      expect(e.errorKey, equals('sell.uploadErrorAuth'));
    });

    test('isRetryable is false', () {
      const e = ImageUploadAuthException();
      expect(e.isRetryable, isFalse);
    });

    test('shouldReport is true (infra-adjacent)', () {
      const e = ImageUploadAuthException();
      expect(e.shouldReport, isTrue);
    });

    test('exposes optional statusCode', () {
      const e = ImageUploadAuthException(statusCode: 401);
      expect(e.statusCode, equals(401));
    });

    test('statusCode defaults to null', () {
      const e = ImageUploadAuthException();
      expect(e.statusCode, isNull);
    });
  });

  group('ImageUploadBlockedException', () {
    test('has errorKey sell.uploadErrorBlocked', () {
      const e = ImageUploadBlockedException();
      expect(e.errorKey, equals('sell.uploadErrorBlocked'));
    });

    test('isRetryable is false', () {
      const e = ImageUploadBlockedException();
      expect(e.isRetryable, isFalse);
    });

    test('shouldReport is false (user error)', () {
      const e = ImageUploadBlockedException();
      expect(e.shouldReport, isFalse);
    });
  });

  group('ImageUploadTooLargeException', () {
    test('has errorKey sell.uploadErrorTooLarge', () {
      const e = ImageUploadTooLargeException();
      expect(e.errorKey, equals('sell.uploadErrorTooLarge'));
    });

    test('isRetryable is false', () {
      const e = ImageUploadTooLargeException();
      expect(e.isRetryable, isFalse);
    });

    test('shouldReport is false (user error)', () {
      const e = ImageUploadTooLargeException();
      expect(e.shouldReport, isFalse);
    });
  });

  group('ImageUploadInvalidException', () {
    test('has errorKey sell.uploadErrorGeneric', () {
      const e = ImageUploadInvalidException();
      expect(e.errorKey, equals('sell.uploadErrorGeneric'));
    });

    test('isRetryable is false', () {
      const e = ImageUploadInvalidException();
      expect(e.isRetryable, isFalse);
    });

    test('shouldReport is false', () {
      const e = ImageUploadInvalidException();
      expect(e.shouldReport, isFalse);
    });
  });

  group('ImageUploadCancelledException', () {
    test('has errorKey sell.uploadErrorGeneric', () {
      const e = ImageUploadCancelledException();
      expect(e.errorKey, equals('sell.uploadErrorGeneric'));
    });

    test('isRetryable is false', () {
      const e = ImageUploadCancelledException();
      expect(e.isRetryable, isFalse);
    });

    test('shouldReport is false (silent drop)', () {
      const e = ImageUploadCancelledException();
      expect(e.shouldReport, isFalse);
    });
  });

  group('toString on base class', () {
    test('includes runtimeType and errorKey for each subtype', () {
      final cases = <ImageUploadException>[
        const ImageUploadNetworkException(),
        const ImageUploadServerException(statusCode: 500),
        const ImageUploadAuthException(),
        const ImageUploadBlockedException(),
        const ImageUploadTooLargeException(),
        const ImageUploadInvalidException(),
        const ImageUploadCancelledException(),
      ];

      for (final e in cases) {
        final s = e.toString();
        expect(s, contains(e.runtimeType.toString()));
        expect(s, contains(e.errorKey));
      }
    });
  });
}
