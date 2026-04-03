import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/sell/data/services/image_picker_service.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/sell_providers.dart';

part 'listing_creation_viewmodel.g.dart';

/// Maximum number of images allowed per listing.
const _maxImages = 12;

/// Debounce duration for auto-saving drafts.
const _draftDebounce = Duration(seconds: 2);

/// ViewModel for the listing creation wizard.
///
/// Manages step navigation, form state, photo operations,
/// and draft auto-saving with a 2-second debounce.
@riverpod
class ListingCreationNotifier extends _$ListingCreationNotifier {
  Timer? _draftTimer;

  @override
  ListingCreationState build() {
    ref.onDispose(() => _draftTimer?.cancel());

    final draftService = ref.read(draftPersistenceServiceProvider);
    final restored = draftService.restore();
    return restored ?? ListingCreationState.initial();
  }

  // ── Photo operations ──

  /// Adds a single photo from the device camera.
  Future<void> addFromCamera() async {
    if (state.imageFiles.length >= _maxImages) return;

    final picker = ref.read(imagePickerServiceProvider);
    final result = await picker.pickFromCamera();

    if (!result.isSuccess) {
      state = state.copyWith(errorKey: () => _errorKeyForResult(result.type));
      return;
    }

    state = state.copyWith(
      imageFiles: [...state.imageFiles, ...result.paths],
      errorKey: () => null,
    );
    _scheduleDraftSave();
  }

  /// Adds one or more photos from the device gallery.
  Future<void> addFromGallery() async {
    final remaining = _maxImages - state.imageFiles.length;
    if (remaining <= 0) return;

    final picker = ref.read(imagePickerServiceProvider);
    final result = await picker.pickFromGallery(maxCount: remaining);

    if (!result.isSuccess) {
      state = state.copyWith(errorKey: () => _errorKeyForResult(result.type));
      return;
    }

    state = state.copyWith(
      imageFiles: [...state.imageFiles, ...result.paths],
      errorKey: () => null,
    );
    _scheduleDraftSave();
  }

  /// Removes the photo at [index].
  void removePhoto(int index) {
    if (index < 0 || index >= state.imageFiles.length) return;

    final updated = [
      ...state.imageFiles.sublist(0, index),
      ...state.imageFiles.sublist(index + 1),
    ];
    state = state.copyWith(imageFiles: updated);
    _scheduleDraftSave();
  }

  /// Reorders photos from [oldIndex] to [newIndex].
  void reorderPhotos(int oldIndex, int newIndex) {
    final photos = [...state.imageFiles];
    final adjustedNew = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final item = photos.removeAt(oldIndex);
    photos.insert(adjustedNew, item);

    state = state.copyWith(imageFiles: photos);
    _scheduleDraftSave();
  }

  // ── Navigation ──

  /// Validates the current step and advances to the next.
  ///
  /// Returns true if navigation succeeded, false if validation failed.
  bool nextStep() {
    switch (state.step) {
      case ListingCreationStep.photos:
        if (state.imageFiles.isEmpty) {
          state = state.copyWith(errorKey: () => 'sell.errorNoPhotos');
          return false;
        }
        state = state.copyWith(
          step: ListingCreationStep.details,
          errorKey: () => null,
        );
        return true;

      case ListingCreationStep.details:
        if (state.title.trim().isEmpty) {
          state = state.copyWith(errorKey: () => 'sell.errorNoTitle');
          return false;
        }
        if (state.priceInCents <= 0) {
          state = state.copyWith(errorKey: () => 'sell.errorNoPrice');
          return false;
        }
        state = state.copyWith(
          step: ListingCreationStep.quality,
          errorKey: () => null,
        );
        return true;

      case ListingCreationStep.quality:
      case ListingCreationStep.publishing:
      case ListingCreationStep.success:
        return false;
    }
  }

  /// Goes back one step. Minimum: photos.
  void previousStep() {
    final previous = switch (state.step) {
      ListingCreationStep.details => ListingCreationStep.photos,
      ListingCreationStep.quality => ListingCreationStep.details,
      _ => null,
    };
    if (previous != null) {
      state = state.copyWith(step: previous, errorKey: () => null);
    }
  }

  // ── Form updates ──

  void updateTitle(String value) {
    state = state.copyWith(title: value);
    _scheduleDraftSave();
  }

  void updateDescription(String value) {
    state = state.copyWith(description: value);
    _scheduleDraftSave();
  }

  void updateCategoryL1(String? id) {
    state = state.copyWith(categoryL1Id: id);
    _scheduleDraftSave();
  }

  void updateCategoryL2(String? id) {
    state = state.copyWith(categoryL2Id: id);
    _scheduleDraftSave();
  }

  void updateCondition(ListingCondition? condition) {
    state = state.copyWith(condition: condition);
    _scheduleDraftSave();
  }

  void updatePrice(int cents) {
    state = state.copyWith(priceInCents: cents);
    _scheduleDraftSave();
  }

  void updateShipping(ShippingCarrier carrier, WeightRange? range) {
    state = state.copyWith(shippingCarrier: carrier, weightRange: range);
    _scheduleDraftSave();
  }

  void updateLocation(String? postcode) {
    state = state.copyWith(location: postcode);
    _scheduleDraftSave();
  }

  // ── Publish / Draft ──

  /// Publishes the listing. On success, clears draft and sets step to success.
  Future<void> publish() async {
    state = state.copyWith(isLoading: true, errorKey: () => null);

    try {
      final useCase = ref.read(createListingUseCaseProvider);
      final listing = await useCase.call(state: state);

      _clearDraft();
      state = state.copyWith(
        isLoading: false,
        step: ListingCreationStep.success,
        createdListingId: listing.id,
      );
    } on Object catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorKey: () => 'sell.publishError',
      );
    }
  }

  /// Saves the current state as a server-side draft.
  Future<void> saveDraft() async {
    state = state.copyWith(isLoading: true, errorKey: () => null);

    try {
      final useCase = ref.read(saveDraftUseCaseProvider);
      await useCase.call(state: state);

      _clearDraft();
      state = state.copyWith(
        isLoading: false,
        step: ListingCreationStep.success,
      );
    } on Object catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorKey: () => 'sell.draftError',
      );
    }
  }

  // ── Private helpers ──

  void _scheduleDraftSave() {
    _draftTimer?.cancel();
    _draftTimer = Timer(_draftDebounce, () {
      ref.read(draftPersistenceServiceProvider).save(state);
    });
  }

  void _clearDraft() {
    _draftTimer?.cancel();
    ref.read(draftPersistenceServiceProvider).clear();
  }

  String _errorKeyForResult(ImagePickerResultType type) => switch (type) {
    ImagePickerResultType.permissionDenied => 'sell.errorPermissionDenied',
    ImagePickerResultType.permissionPermanentlyDenied =>
      'sell.errorPermissionPermanent',
    ImagePickerResultType.fileTooLarge => 'sell.errorFileTooLarge',
    ImagePickerResultType.unsupportedFormat => 'sell.errorUnsupportedFormat',
    _ => 'sell.errorImagePicker',
  };
}
