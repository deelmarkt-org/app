import 'package:uuid/uuid.dart';

import 'package:deelmarkt/features/sell/data/services/image_picker_service.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state_copy_with.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_queue.dart';

/// Photo operation results — pure functions operating on [ListingCreationState].
///
/// Extracted from [ListingCreationNotifier] to keep the ViewModel under
/// the 150-line limit (CLAUDE.md §2.1).
abstract final class PhotoOperations {
  static const maxImages = 12;
  static const _uuid = Uuid();

  /// Applies a pick result to state; returns new state + fresh images for enqueue.
  static ({ListingCreationState state, List<SellImage> newImages}) addPhotos(
    ListingCreationState state,
    ImagePickerResult result,
  ) {
    if (!result.isSuccess) {
      return (
        state: state.copyWith(errorKey: () => errorKeyFor(result.type)),
        newImages: const [],
      );
    }
    final newImages = result.paths
        .map((p) => SellImage(id: _uuid.v4(), localPath: p))
        .toList(growable: false);
    return (
      state: state.copyWith(
        imageFiles: [...state.imageFiles, ...newImages],
        errorKey: () => null,
      ),
      newImages: newImages,
    );
  }

  /// Removes the photo with [id] from state. Returns the removed image
  /// (if any) so the caller can clean up the upload queue and Storage.
  static ({ListingCreationState state, SellImage? removed}) removeById(
    ListingCreationState state,
    String id,
  ) {
    final index = state.imageFiles.indexWhere((i) => i.id == id);
    if (index == -1) return (state: state, removed: null);
    final removed = state.imageFiles[index];
    return (
      state: state.copyWith(
        imageFiles: [
          ...state.imageFiles.sublist(0, index),
          ...state.imageFiles.sublist(index + 1),
        ],
      ),
      removed: removed,
    );
  }

  /// Reorders a photo from [oldIndex] to [newIndex].
  static ListingCreationState reorder(
    ListingCreationState state,
    int oldIndex,
    int newIndex,
  ) {
    final photos = [...state.imageFiles];
    final adj = newIndex > oldIndex ? newIndex - 1 : newIndex;
    photos.insert(adj, photos.removeAt(oldIndex));
    return state.copyWith(imageFiles: photos);
  }

  /// Id-based state patch — drops silently if [id] no longer exists.
  static ListingCreationState patchImage(
    ListingCreationState state,
    String id,
    SellImage Function(SellImage current) transform,
  ) {
    final index = state.imageFiles.indexWhere((i) => i.id == id);
    if (index == -1) return state;
    final next = [...state.imageFiles];
    next[index] = transform(next[index]);
    return state.copyWith(imageFiles: next);
  }

  /// Resets a failed image to [ImageUploadStatus.pending] so the queue can
  /// re-enqueue it. Drops silently if [id] is not found or not retryable.
  static ListingCreationState markRetry(
    ListingCreationState state,
    String id,
  ) => patchImage(
    state,
    id,
    (i) => i.copyWith(
      status: ImageUploadStatus.pending,
      errorKey: () => null,
      userRetryCount: i.userRetryCount + 1,
    ),
  );

  /// Apply a [PhotoUploadOutcome] from the queue to state via id-based patch.
  static ListingCreationState applyOutcome(
    ListingCreationState state,
    PhotoUploadOutcome outcome,
  ) {
    return switch (outcome) {
      PhotoUploadStarted() => patchImage(
        state,
        outcome.id,
        (img) => img.copyWith(
          status: ImageUploadStatus.uploading,
          errorKey: () => null,
        ),
      ),
      PhotoUploadSucceeded() => patchImage(
        state,
        outcome.id,
        (img) => img.copyWith(
          status: ImageUploadStatus.uploaded,
          storagePath: () => outcome.response.storagePath,
          deliveryUrl: () => outcome.response.deliveryUrl,
          publicId: () => outcome.response.publicId,
          width: () => outcome.response.width,
          height: () => outcome.response.height,
          bytes: () => outcome.response.bytes,
          format: () => outcome.response.format,
          errorKey: () => null,
        ),
      ),
      PhotoUploadFailed() => patchImage(
        state,
        outcome.id,
        (img) => img.copyWith(
          status: ImageUploadStatus.failed,
          errorKey: () => outcome.exception.messageKey,
          isRetryable: outcome.isRetryable,
        ),
      ),
    };
  }

  /// Maps a picker result type to an l10n error key.
  static String errorKeyFor(ImagePickerResultType t) => switch (t) {
    ImagePickerResultType.permissionDenied => 'sell.errorPermissionDenied',
    ImagePickerResultType.permissionPermanentlyDenied =>
      'sell.errorPermissionPermanent',
    ImagePickerResultType.fileTooLarge => 'sell.errorFileTooLarge',
    ImagePickerResultType.unsupportedFormat => 'sell.errorUnsupportedFormat',
    _ => 'sell.errorImagePicker',
  };
}
