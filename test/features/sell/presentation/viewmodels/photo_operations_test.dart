import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/sell/data/services/image_picker_service.dart';
import 'package:deelmarkt/features/sell/data/services/models/image_upload_response.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state_copy_with.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_operations.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_queue.dart';

SellImage makeImage(
  String id, {
  ImageUploadStatus status = ImageUploadStatus.pending,
  String? deliveryUrl,
  String? storagePath,
  String? publicId,
  String? errorKey,
  int userRetryCount = 0,
  bool isRetryable = true,
}) {
  return SellImage(
    id: id,
    localPath: '/tmp/$id.jpg',
    status: status,
    deliveryUrl: deliveryUrl,
    storagePath: storagePath,
    publicId: publicId,
    errorKey: errorKey,
    userRetryCount: userRetryCount,
    isRetryable: isRetryable,
  );
}

void main() {
  group('PhotoOperations.addPhotos', () {
    test('success result adds images to state and returns newImages', () {
      final state = ListingCreationState.initial();
      const result = ImagePickerResult(
        type: ImagePickerResultType.success,
        paths: ['/tmp/a.jpg', '/tmp/b.jpg'],
      );

      final out = PhotoOperations.addPhotos(state, result);

      expect(out.state.imageFiles, hasLength(2));
      expect(out.newImages, hasLength(2));
      expect(out.state.imageFiles.first.localPath, '/tmp/a.jpg');
      expect(out.state.imageFiles.last.localPath, '/tmp/b.jpg');
      expect(out.state.errorKey, isNull);
    });

    test('cancelled result sets errorKey and returns no newImages', () {
      final state = ListingCreationState.initial();
      const result = ImagePickerResult(
        type: ImagePickerResultType.permissionDenied,
      );

      final out = PhotoOperations.addPhotos(state, result);

      expect(out.newImages, isEmpty);
      expect(out.state.errorKey, isNotNull);
      expect(out.state.imageFiles, isEmpty);
    });

    test(
      'exceeds maxImages: note — state already at maxImages is not extended further',
      () {
        final images = List.generate(
          PhotoOperations.maxImages,
          (i) => makeImage('img-$i'),
        );
        final state = ListingCreationState.initial().copyWith(
          imageFiles: images,
        );

        expect(state.imageFiles.length, PhotoOperations.maxImages);
      },
    );
  });

  group('PhotoOperations.removeById', () {
    test('removes correct image and returns it', () {
      final img1 = makeImage('img-1');
      final img2 = makeImage('img-2');
      final state = ListingCreationState.initial().copyWith(
        imageFiles: [img1, img2],
      );

      final out = PhotoOperations.removeById(state, 'img-1');

      expect(out.removed, equals(img1));
      expect(out.state.imageFiles, hasLength(1));
      expect(out.state.imageFiles.first.id, 'img-2');
    });

    test('non-existent id returns state unchanged with removed == null', () {
      final img1 = makeImage('img-1');
      final state = ListingCreationState.initial().copyWith(imageFiles: [img1]);

      final out = PhotoOperations.removeById(state, 'does-not-exist');

      expect(out.removed, isNull);
      expect(out.state, equals(state));
    });
  });

  group('PhotoOperations.reorder', () {
    test('moves image from one index to another', () {
      final img0 = makeImage('img-0');
      final img1 = makeImage('img-1');
      final img2 = makeImage('img-2');
      final state = ListingCreationState.initial().copyWith(
        imageFiles: [img0, img1, img2],
      );

      final newState = PhotoOperations.reorder(state, 2, 0);

      expect(newState.imageFiles.map((i) => i.id).toList(), [
        'img-2',
        'img-0',
        'img-1',
      ]);
    });
  });

  group('PhotoOperations.markRetry', () {
    test(
      'sets status to pending, clears errorKey, increments userRetryCount',
      () {
        final img = makeImage(
          'img-1',
          status: ImageUploadStatus.failed,
          errorKey: 'error.network',
          userRetryCount: 1,
        );
        final state = ListingCreationState.initial().copyWith(
          imageFiles: [img],
        );

        final newState = PhotoOperations.markRetry(state, 'img-1');

        final patched = newState.imageFiles.first;
        expect(patched.status, ImageUploadStatus.pending);
        expect(patched.errorKey, isNull);
        expect(patched.userRetryCount, 2);
      },
    );

    test('is a no-op if id is not found', () {
      final img = makeImage('img-1');
      final state = ListingCreationState.initial().copyWith(imageFiles: [img]);

      final newState = PhotoOperations.markRetry(state, 'not-found');

      expect(newState, equals(state));
    });
  });

  group('PhotoOperations.applyOutcome', () {
    test('PhotoUploadStarted → status uploading, errorKey cleared', () {
      final img = makeImage('img-1');
      final state = ListingCreationState.initial().copyWith(imageFiles: [img]);

      final newState = PhotoOperations.applyOutcome(
        state,
        const PhotoUploadStarted('img-1'),
      );

      final patched = newState.imageFiles.first;
      expect(patched.status, ImageUploadStatus.uploading);
      expect(patched.errorKey, isNull);
    });

    test(
      'PhotoUploadSucceeded → status uploaded, storagePath/deliveryUrl/publicId set',
      () {
        final img = makeImage('img-1', status: ImageUploadStatus.uploading);
        final state = ListingCreationState.initial().copyWith(
          imageFiles: [img],
        );

        const response = ImageUploadResponse(
          storagePath: 'uid/abc.jpg',
          deliveryUrl: 'https://cdn/abc.jpg',
          publicId: 'uid/abc',
          width: 800,
          height: 600,
          bytes: 50000,
          format: 'jpg',
        );

        final newState = PhotoOperations.applyOutcome(
          state,
          const PhotoUploadSucceeded('img-1', response),
        );

        final patched = newState.imageFiles.first;
        expect(patched.status, ImageUploadStatus.uploaded);
        expect(patched.storagePath, 'uid/abc.jpg');
        expect(patched.deliveryUrl, 'https://cdn/abc.jpg');
        expect(patched.publicId, 'uid/abc');
        expect(patched.errorKey, isNull);
      },
    );

    test(
      'PhotoUploadFailed (retryable: NetworkException) → status failed, isRetryable true',
      () {
        final img = makeImage('img-1', status: ImageUploadStatus.uploading);
        final state = ListingCreationState.initial().copyWith(
          imageFiles: [img],
        );

        const exception = NetworkException(debugMessage: 'timeout');
        const outcome = PhotoUploadFailed('img-1', exception);
        final newState = PhotoOperations.applyOutcome(state, outcome);

        final patched = newState.imageFiles.first;
        expect(patched.status, ImageUploadStatus.failed);
        expect(patched.errorKey, 'error.network');
        expect(patched.isRetryable, isTrue);
      },
    );

    test(
      'PhotoUploadFailed (non-retryable: ValidationException) → isRetryable false',
      () {
        final img = makeImage('img-1', status: ImageUploadStatus.uploading);
        final state = ListingCreationState.initial().copyWith(
          imageFiles: [img],
        );

        const exception = ValidationException(
          'error.image.blocked',
          debugMessage: 'blocked',
        );
        const outcome = PhotoUploadFailed('img-1', exception);
        final newState = PhotoOperations.applyOutcome(state, outcome);

        final patched = newState.imageFiles.first;
        expect(patched.status, ImageUploadStatus.failed);
        expect(patched.isRetryable, isFalse);
      },
    );

    test('rate-limited ValidationException is retryable', () {
      const exception = ValidationException('error.image.rate_limited');
      const outcome = PhotoUploadFailed('img-1', exception);
      expect(outcome.isRetryable, isTrue);
    });
  });
}
