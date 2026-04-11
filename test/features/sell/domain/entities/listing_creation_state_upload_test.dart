import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state_copy_with.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state_upload.dart';

void main() {
  group('ListingCreationStateUpload', () {
    SellImage makeImage(
      String id, {
      ImageUploadStatus status = ImageUploadStatus.pending,
      String? deliveryUrl,
    }) {
      return SellImage(
        id: id,
        localPath: '/tmp/$id.jpg',
        status: status,
        deliveryUrl: deliveryUrl,
      );
    }

    test('uploadedCount counts only uploaded-status images', () {
      final state = ListingCreationState.initial().copyWith(
        imageFiles: [
          makeImage('a', status: ImageUploadStatus.uploaded),
          makeImage('b'),
          makeImage('c', status: ImageUploadStatus.uploaded),
          makeImage('d', status: ImageUploadStatus.failed),
        ],
      );
      expect(state.uploadedCount, 2);
    });

    test('hasPendingUploads is true when any image is pending', () {
      final state = ListingCreationState.initial().copyWith(
        imageFiles: [
          makeImage('a', status: ImageUploadStatus.uploaded),
          makeImage('b'),
        ],
      );
      expect(state.hasPendingUploads, isTrue);
    });

    test('hasPendingUploads is true when any image is uploading', () {
      final state = ListingCreationState.initial().copyWith(
        imageFiles: [makeImage('a', status: ImageUploadStatus.uploading)],
      );
      expect(state.hasPendingUploads, isTrue);
    });

    test('hasPendingUploads is false when all are uploaded or failed', () {
      final state = ListingCreationState.initial().copyWith(
        imageFiles: [
          makeImage('a', status: ImageUploadStatus.uploaded),
          makeImage('b', status: ImageUploadStatus.failed),
        ],
      );
      expect(state.hasPendingUploads, isFalse);
    });

    test('hasFailedUploads is true when any image is failed', () {
      final state = ListingCreationState.initial().copyWith(
        imageFiles: [
          makeImage('a', status: ImageUploadStatus.uploaded),
          makeImage('b', status: ImageUploadStatus.failed),
        ],
      );
      expect(state.hasFailedUploads, isTrue);
    });

    test('hasFailedUploads is false when none are failed', () {
      final state = ListingCreationState.initial().copyWith(
        imageFiles: [
          makeImage('a', status: ImageUploadStatus.uploaded),
          makeImage('b'),
        ],
      );
      expect(state.hasFailedUploads, isFalse);
    });

    test('allImagesUploaded is true only when non-empty and all uploaded', () {
      final state = ListingCreationState.initial().copyWith(
        imageFiles: [
          makeImage('a', status: ImageUploadStatus.uploaded),
          makeImage('b', status: ImageUploadStatus.uploaded),
        ],
      );
      expect(state.allImagesUploaded, isTrue);
    });

    test('allImagesUploaded is false when empty', () {
      final state = ListingCreationState.initial();
      expect(state.allImagesUploaded, isFalse);
    });

    test('allImagesUploaded is false when some are not uploaded', () {
      final state = ListingCreationState.initial().copyWith(
        imageFiles: [
          makeImage('a', status: ImageUploadStatus.uploaded),
          makeImage('b'),
        ],
      );
      expect(state.allImagesUploaded, isFalse);
    });

    test('uploadedDeliveryUrls returns only uploaded images delivery URLs', () {
      final state = ListingCreationState.initial().copyWith(
        imageFiles: [
          makeImage(
            'a',
            status: ImageUploadStatus.uploaded,
            deliveryUrl: 'https://cdn/a.jpg',
          ),
          makeImage('b'),
          makeImage(
            'c',
            status: ImageUploadStatus.uploaded,
            deliveryUrl: 'https://cdn/c.jpg',
          ),
        ],
      );
      expect(state.uploadedDeliveryUrls, [
        'https://cdn/a.jpg',
        'https://cdn/c.jpg',
      ]);
    });
  });
}
