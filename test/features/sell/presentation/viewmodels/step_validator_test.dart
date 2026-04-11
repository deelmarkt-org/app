import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state_copy_with.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state_upload.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/step_validator.dart';

void main() {
  group('StepValidator.validate', () {
    group('photos step', () {
      test('empty imageFiles → sell.errorNoPhotos', () {
        final state = ListingCreationState.initial();
        expect(state.step, ListingCreationStep.photos);
        expect(StepValidator.validate(state), 'sell.errorNoPhotos');
      });

      test('image in uploading status → sell.errorImagesUploading', () {
        final state = ListingCreationState.initial().copyWith(
          imageFiles: [
            const SellImage(
              id: 'img-1',
              localPath: '/tmp/img-1.jpg',
              status: ImageUploadStatus.uploading,
            ),
          ],
        );
        // hasPendingUploads is checked after hasFailedUploads in the validator.
        // The state has no failed images, so pending/uploading fires first.
        expect(state.hasPendingUploads, isTrue);
        expect(state.hasFailedUploads, isFalse);
        expect(StepValidator.validate(state), 'sell.errorImagesUploading');
      });

      test('failed image → sell.errorImagesFailed', () {
        final state = ListingCreationState.initial().copyWith(
          imageFiles: [
            const SellImage(
              id: 'img-1',
              localPath: '/tmp/img-1.jpg',
              status: ImageUploadStatus.failed,
              errorKey: 'sell.uploadErrorNetwork',
            ),
          ],
        );
        expect(StepValidator.validate(state), 'sell.errorImagesFailed');
      });

      test('one uploaded image → null (valid)', () {
        final state = ListingCreationState.initial().copyWith(
          imageFiles: [
            const SellImage(
              id: 'img-1',
              localPath: '/tmp/img-1.jpg',
              status: ImageUploadStatus.uploaded,
              deliveryUrl: 'https://cdn/img-1.jpg',
            ),
          ],
        );
        expect(StepValidator.validate(state), isNull);
      });
    });

    group('details step', () {
      ListingCreationState detailsBase() =>
          ListingCreationState.initial().copyWith(
            step: ListingCreationStep.details,
            imageFiles: [
              const SellImage(
                id: 'img-1',
                localPath: '/tmp/img-1.jpg',
                status: ImageUploadStatus.uploaded,
                deliveryUrl: 'https://cdn/img-1.jpg',
              ),
            ],
            title: 'Test Item',
            priceInCents: 500,
            categoryL1Id: () => 'cat-1',
          );

      test('empty title → sell.errorNoTitle', () {
        final state = detailsBase().copyWith(title: '');
        expect(StepValidator.validate(state), 'sell.errorNoTitle');
      });

      test('priceInCents == 0 → sell.errorNoPrice', () {
        final state = detailsBase().copyWith(priceInCents: 0);
        expect(StepValidator.validate(state), 'sell.errorNoPrice');
      });

      test('categoryL1Id == null → sell.errorNoCategory', () {
        final state = detailsBase().copyWith(categoryL1Id: () => null);
        expect(StepValidator.validate(state), 'sell.errorNoCategory');
      });

      test('all filled → null (valid)', () {
        expect(StepValidator.validate(detailsBase()), isNull);
      });
    });

    group('quality step', () {
      test('always returns null', () {
        final state = ListingCreationState.initial().copyWith(
          step: ListingCreationStep.quality,
        );
        expect(StepValidator.validate(state), isNull);
      });
    });
  });

  group('StepValidator.next', () {
    test('next(photos) == details', () {
      expect(
        StepValidator.next(ListingCreationStep.photos),
        ListingCreationStep.details,
      );
    });

    test('next(details) == quality', () {
      expect(
        StepValidator.next(ListingCreationStep.details),
        ListingCreationStep.quality,
      );
    });

    test('next(quality) == null', () {
      expect(StepValidator.next(ListingCreationStep.quality), isNull);
    });
  });

  group('StepValidator.previous', () {
    test('previous(details) == photos', () {
      expect(
        StepValidator.previous(ListingCreationStep.details),
        ListingCreationStep.photos,
      );
    });

    test('previous(photos) == null', () {
      expect(StepValidator.previous(ListingCreationStep.photos), isNull);
    });
  });
}
