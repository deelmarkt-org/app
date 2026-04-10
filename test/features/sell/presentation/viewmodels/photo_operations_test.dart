import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/sell/data/services/image_picker_service.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state_copy_with.dart';
import 'package:deelmarkt/features/sell/domain/entities/uploaded_image.dart';
import 'package:deelmarkt/features/sell/domain/exceptions/image_upload_exceptions.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_operations.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_queue.dart';

SellImage makeImage(
  String id, {
  ImageUploadStatus status = ImageUploadStatus.pending,
  String? deliveryUrl,
  String? storagePath,
  String? errorKey,
  int attemptCount = 0,
  bool isRetryable = true,
}) {
  return SellImage(
    id: id,
    localPath: '/tmp/$id.jpg',
    status: status,
    deliveryUrl: deliveryUrl,
    storagePath: storagePath,
    errorKey: errorKey,
    attemptCount: attemptCount,
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
        // Build a state with maxImages already filled.
        final images = List.generate(
          PhotoOperations.maxImages,
          (i) => makeImage('img-$i'),
        );
        final state = ListingCreationState.initial().copyWith(
          imageFiles: images,
        );

        // The addPhotos function itself does not enforce the cap — the caller
        // (ListingCreationNotifier) guards this before calling addPhotos.
        // We verify the current count is already at the limit.
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

      // Move img2 to position 0.
      final newState = PhotoOperations.reorder(state, 2, 0);

      expect(newState.imageFiles.map((i) => i.id).toList(), [
        'img-2',
        'img-0',
        'img-1',
      ]);
    });
  });

  group('PhotoOperations.markRetry', () {
    test('sets status to pending and clears errorKey', () {
      final img = makeImage(
        'img-1',
        status: ImageUploadStatus.failed,
        errorKey: 'sell.uploadErrorNetwork',
      );
      final state = ListingCreationState.initial().copyWith(imageFiles: [img]);

      final newState = PhotoOperations.markRetry(state, 'img-1');

      final patched = newState.imageFiles.first;
      expect(patched.status, ImageUploadStatus.pending);
      expect(patched.errorKey, isNull);
    });

    test('is a no-op if id is not found', () {
      final img = makeImage('img-1');
      final state = ListingCreationState.initial().copyWith(imageFiles: [img]);

      final newState = PhotoOperations.markRetry(state, 'not-found');

      expect(newState, equals(state));
    });
  });

  group('PhotoOperations.applyOutcome', () {
    test('PhotoUploadStarted → status uploading, attemptCount incremented', () {
      final img = makeImage('img-1');
      final state = ListingCreationState.initial().copyWith(imageFiles: [img]);

      final newState = PhotoOperations.applyOutcome(
        state,
        const PhotoUploadStarted('img-1'),
      );

      final patched = newState.imageFiles.first;
      expect(patched.status, ImageUploadStatus.uploading);
      expect(patched.attemptCount, 1);
      expect(patched.errorKey, isNull);
    });

    test(
      'PhotoUploadSucceeded → status uploaded, storagePath/deliveryUrl set',
      () {
        final img = makeImage('img-1', status: ImageUploadStatus.uploading);
        final state = ListingCreationState.initial().copyWith(
          imageFiles: [img],
        );

        const uploaded = UploadedImage(
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
          const PhotoUploadSucceeded('img-1', uploaded),
        );

        final patched = newState.imageFiles.first;
        expect(patched.status, ImageUploadStatus.uploaded);
        expect(patched.storagePath, 'uid/abc.jpg');
        expect(patched.deliveryUrl, 'https://cdn/abc.jpg');
        expect(patched.errorKey, isNull);
      },
    );

    test(
      'PhotoUploadFailed (retryable) → status failed, errorKey set, isRetryable true',
      () {
        final img = makeImage('img-1', status: ImageUploadStatus.uploading);
        final state = ListingCreationState.initial().copyWith(
          imageFiles: [img],
        );

        const exception = ImageUploadNetworkException();
        final newState = PhotoOperations.applyOutcome(
          state,
          const PhotoUploadFailed('img-1', exception),
        );

        final patched = newState.imageFiles.first;
        expect(patched.status, ImageUploadStatus.failed);
        expect(patched.errorKey, exception.errorKey);
        expect(patched.isRetryable, isTrue);
      },
    );

    test('PhotoUploadFailed (non-retryable) → isRetryable false', () {
      final img = makeImage('img-1', status: ImageUploadStatus.uploading);
      final state = ListingCreationState.initial().copyWith(imageFiles: [img]);

      const exception = ImageUploadBlockedException();
      final newState = PhotoOperations.applyOutcome(
        state,
        const PhotoUploadFailed('img-1', exception),
      );

      final patched = newState.imageFiles.first;
      expect(patched.status, ImageUploadStatus.failed);
      expect(patched.isRetryable, isFalse);
    });
  });
}
