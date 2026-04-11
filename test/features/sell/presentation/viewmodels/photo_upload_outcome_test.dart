import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/sell/data/services/models/image_upload_response.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_outcome.dart';

void main() {
  const id = 'img-1';

  group('PhotoUploadOutcome sealed hierarchy', () {
    test('PhotoUploadStarted carries id', () {
      const o = PhotoUploadStarted(id);
      expect(o.id, id);
    });

    test('PhotoUploadSucceeded carries id and response', () {
      const response = ImageUploadResponse(
        storagePath: 'uid/x.jpg',
        deliveryUrl: 'https://cdn/x.jpg',
        publicId: 'uid/x',
        width: 1920,
        height: 1080,
        bytes: 204800,
        format: 'jpg',
      );
      const o = PhotoUploadSucceeded(id, response);
      expect(o.id, id);
      expect(o.response, response);
    });

    group('PhotoUploadFailed.isRetryable', () {
      test('NetworkException → retryable', () {
        const o = PhotoUploadFailed(
          id,
          NetworkException(debugMessage: 'timeout'),
        );
        expect(o.isRetryable, isTrue);
      });

      test('ValidationException rate_limited → retryable', () {
        const o = PhotoUploadFailed(
          id,
          ValidationException('error.image.rate_limited', debugMessage: '429'),
        );
        expect(o.isRetryable, isTrue);
      });

      test('AuthException → not retryable', () {
        const o = PhotoUploadFailed(
          id,
          AuthException('error.auth.unauthenticated'),
        );
        expect(o.isRetryable, isFalse);
      });

      test('ValidationException blocked → not retryable', () {
        const o = PhotoUploadFailed(
          id,
          ValidationException('error.image.blocked'),
        );
        expect(o.isRetryable, isFalse);
      });
    });
  });
}
