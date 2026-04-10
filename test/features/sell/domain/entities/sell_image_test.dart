import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/sell/domain/entities/sell_image.dart';

void main() {
  group('SellImage', () {
    const id = 'abc-123';
    const localPath = '/tmp/photo.jpg';

    test('defaults: pending status, attemptCount 0, isRetryable true', () {
      const image = SellImage(id: id, localPath: localPath);

      expect(image.id, id);
      expect(image.localPath, localPath);
      expect(image.status, ImageUploadStatus.pending);
      expect(image.storagePath, isNull);
      expect(image.deliveryUrl, isNull);
      expect(image.errorKey, isNull);
      expect(image.attemptCount, 0);
      expect(image.isRetryable, isTrue);
    });

    group('status getters', () {
      test('pending → isPending true, isUploaded/isFailed false', () {
        const image = SellImage(id: id, localPath: localPath);
        expect(image.isPending, isTrue);
        expect(image.isUploaded, isFalse);
        expect(image.isFailed, isFalse);
        expect(image.canRetry, isFalse);
      });

      test('uploading → isPending true, isUploaded/isFailed false', () {
        const image = SellImage(
          id: id,
          localPath: localPath,
          status: ImageUploadStatus.uploading,
        );
        expect(image.isPending, isTrue);
        expect(image.isUploaded, isFalse);
        expect(image.isFailed, isFalse);
      });

      test('uploaded → isUploaded true', () {
        const image = SellImage(
          id: id,
          localPath: localPath,
          status: ImageUploadStatus.uploaded,
          deliveryUrl: 'https://cdn/x.jpg',
        );
        expect(image.isUploaded, isTrue);
        expect(image.isPending, isFalse);
        expect(image.isFailed, isFalse);
      });

      test('failed retryable → isFailed true, canRetry true', () {
        const image = SellImage(
          id: id,
          localPath: localPath,
          status: ImageUploadStatus.failed,
          errorKey: 'sell.uploadErrorNetwork',
        );
        expect(image.isFailed, isTrue);
        expect(image.canRetry, isTrue);
      });

      test('failed terminal → canRetry false', () {
        const image = SellImage(
          id: id,
          localPath: localPath,
          status: ImageUploadStatus.failed,
          errorKey: 'sell.uploadErrorBlocked',
          isRetryable: false,
        );
        expect(image.isFailed, isTrue);
        expect(image.canRetry, isFalse);
      });
    });

    group('copyWith', () {
      const base = SellImage(id: id, localPath: localPath);

      test('no args returns equal instance', () {
        expect(base.copyWith(), equals(base));
      });

      test('overrides status and deliveryUrl', () {
        final next = base.copyWith(
          status: ImageUploadStatus.uploaded,
          deliveryUrl: () => 'https://cdn/x.jpg',
          storagePath: () => 'uid/x.jpg',
        );
        expect(next.status, ImageUploadStatus.uploaded);
        expect(next.deliveryUrl, 'https://cdn/x.jpg');
        expect(next.storagePath, 'uid/x.jpg');
        expect(next.id, base.id);
        expect(next.localPath, base.localPath);
      });

      test('clears nullable fields via explicit null functions', () {
        const withValues = SellImage(
          id: id,
          localPath: localPath,
          errorKey: 'sell.uploadErrorNetwork',
          deliveryUrl: 'https://cdn/x.jpg',
        );
        final cleared = withValues.copyWith(
          errorKey: () => null,
          deliveryUrl: () => null,
        );
        expect(cleared.errorKey, isNull);
        expect(cleared.deliveryUrl, isNull);
      });

      test('increments attemptCount', () {
        final next = base.copyWith(attemptCount: 3);
        expect(next.attemptCount, 3);
      });

      test('overrides isRetryable', () {
        final next = base.copyWith(isRetryable: false);
        expect(next.isRetryable, isFalse);
      });
    });

    test('Equatable: equal instances are equal', () {
      const a = SellImage(id: id, localPath: localPath);
      const b = SellImage(id: id, localPath: localPath);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('Equatable: differing status breaks equality', () {
      const a = SellImage(id: id, localPath: localPath);
      const b = SellImage(
        id: id,
        localPath: localPath,
        status: ImageUploadStatus.uploaded,
      );
      expect(a, isNot(equals(b)));
    });
  });
}
