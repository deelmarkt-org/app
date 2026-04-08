import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state_copy_with.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/listing_form_updaters.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_operations.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/sell_providers.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/step_validator.dart';

part 'listing_creation_viewmodel.g.dart';

const _draftDebounce = Duration(seconds: 2);

/// ViewModel for the listing creation wizard.
@riverpod
class ListingCreationNotifier extends _$ListingCreationNotifier {
  Timer? _draftTimer;

  @override
  ListingCreationState build() {
    ref.onDispose(() => _draftTimer?.cancel());
    return ref.read(draftPersistenceServiceProvider).restore() ??
        ListingCreationState.initial();
  }

  Future<void> addFromCamera() async {
    if (state.imageFiles.length >= PhotoOperations.maxImages) return;
    final result = await ref.read(imagePickerServiceProvider).pickFromCamera();
    _apply(PhotoOperations.addPhotos(state, result));
  }

  Future<void> addFromGallery() async {
    final remaining = PhotoOperations.maxImages - state.imageFiles.length;
    if (remaining <= 0) return;
    final picker = ref.read(imagePickerServiceProvider);
    final result = await picker.pickFromGallery(maxCount: remaining);
    _apply(PhotoOperations.addPhotos(state, result));
  }

  void removePhoto(int index) => _apply(PhotoOperations.remove(state, index));
  void reorderPhotos(int old, int next) =>
      _apply(PhotoOperations.reorder(state, old, next));

  // ── Navigation ──

  bool nextStep() {
    final error = StepValidator.validate(state);
    if (error != null) {
      state = state.copyWith(errorKey: () => error);
      return false;
    }
    final next = StepValidator.next(state.step);
    if (next == null) return false;
    state = state.copyWith(step: next, errorKey: () => null);
    return true;
  }

  void previousStep() {
    final prev = StepValidator.previous(state.step);
    if (prev != null) state = state.copyWith(step: prev, errorKey: () => null);
  }

  void updateTitle(String v) => _apply(ListingFormUpdaters.title(state, v));
  void updateDescription(String v) =>
      _apply(ListingFormUpdaters.description(state, v));
  void updateCategoryL1(String? id) =>
      _apply(ListingFormUpdaters.categoryL1(state, id));
  void updateCategoryL2(String? id) =>
      _apply(ListingFormUpdaters.categoryL2(state, id));
  void updateCondition(ListingCondition? c) =>
      _apply(ListingFormUpdaters.condition(state, c));
  void updatePrice(int cents) =>
      _apply(ListingFormUpdaters.price(state, cents));
  void updateShipping(ShippingCarrier carrier, WeightRange? range) =>
      _apply(ListingFormUpdaters.shipping(state, carrier, range));
  void updateLocation(String? postcode) =>
      _apply(ListingFormUpdaters.location(state, postcode));

  Future<void> publish() => _submit(() async {
    final l = await ref.read(createListingUseCaseProvider).call(state: state);
    return state.copyWith(
      isLoading: false,
      step: ListingCreationStep.success,
      createdListingId: () => l.id,
    );
  }, 'sell.publishError');

  Future<void> saveDraft() => _submit(() async {
    await ref.read(saveDraftUseCaseProvider).call(state: state);
    return state.copyWith(isLoading: false, step: ListingCreationStep.success);
  }, 'sell.draftError');

  Future<void> _submit(
    Future<ListingCreationState> Function() action,
    String errorKey,
  ) async {
    state = state.copyWith(isLoading: true, errorKey: () => null);
    try {
      state = await action();
      _clearDraft();
    } on Object catch (_) {
      state = state.copyWith(isLoading: false, errorKey: () => errorKey);
    }
  }

  void _apply(ListingCreationState next) {
    state = next;
    _scheduleDraftSave();
  }

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
}
