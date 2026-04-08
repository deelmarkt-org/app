import 'package:deelmarkt/features/sell/data/services/image_picker_service.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state_copy_with.dart';

/// Photo operation results — pure functions operating on [ListingCreationState].
///
/// Extracted from [ListingCreationNotifier] to keep the ViewModel under
/// the 150-line limit (CLAUDE.md §2.1).
abstract final class PhotoOperations {
  static const maxImages = 12;

  /// Applies a successful pick result to state.
  static ListingCreationState addPhotos(
    ListingCreationState state,
    ImagePickerResult result,
  ) {
    if (!result.isSuccess) {
      return state.copyWith(errorKey: () => errorKeyFor(result.type));
    }
    return state.copyWith(
      imageFiles: [...state.imageFiles, ...result.paths],
      errorKey: () => null,
    );
  }

  /// Removes the photo at [index] from state.
  static ListingCreationState remove(ListingCreationState state, int index) {
    if (index < 0 || index >= state.imageFiles.length) return state;
    return state.copyWith(
      imageFiles: [
        ...state.imageFiles.sublist(0, index),
        ...state.imageFiles.sublist(index + 1),
      ],
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
