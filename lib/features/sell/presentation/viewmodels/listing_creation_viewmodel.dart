import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/sell/data/services/sell_services_providers.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state_copy_with.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/listing_form_updaters.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_operations.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_queue.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/sell_providers.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/step_validator.dart';

part 'listing_creation_viewmodel.g.dart';

typedef _F = ListingFormUpdaters;
const _draftDebounce = Duration(seconds: 2);

@riverpod
class ListingCreationNotifier extends _$ListingCreationNotifier {
  Timer? _draftTimer;
  StreamSubscription<PhotoUploadOutcome>? _outcomeSub;

  @override
  ListingCreationState build() {
    final queue = ref.watch(photoUploadQueueProvider);
    _outcomeSub = queue.outcomes.listen(_onOutcome);
    ref.onDispose(() {
      _draftTimer?.cancel();
      _outcomeSub?.cancel();
    });
    return ref.read(draftPersistenceServiceProvider).restore() ??
        ListingCreationState.initial();
  }

  Future<void> addFromCamera() async {
    if (state.imageFiles.length >= PhotoOperations.maxImages) return;
    final r = await ref.read(imagePickerServiceProvider).pickFromCamera();
    _applyPick(PhotoOperations.addPhotos(state, r));
  }

  Future<void> addFromGallery() async {
    final remaining = PhotoOperations.maxImages - state.imageFiles.length;
    if (remaining <= 0) return;
    final svc = ref.read(imagePickerServiceProvider);
    final r = await svc.pickFromGallery(maxCount: remaining);
    _applyPick(PhotoOperations.addPhotos(state, r));
  }

  void removePhoto(String id) {
    final out = PhotoOperations.removeById(state, id);
    if (out.removed == null) return;
    apply(out.state);
    ref.read(photoUploadQueueProvider).cancel(id);
    final sp = out.removed!.storagePath;
    if (sp == null) return;
    unawaited(ref.read(imageUploadServiceProvider).deleteStorageObject(sp));
  }

  void reorderPhotos(int old, int next) =>
      apply(PhotoOperations.reorder(state, old, next));

  void retryUpload(String id) {
    final idx = state.imageFiles.indexWhere((i) => i.id == id);
    if (idx == -1 || !state.imageFiles[idx].canRetry) return;
    final img = state.imageFiles[idx];
    apply(PhotoOperations.markRetry(state, id));
    ref
        .read(photoUploadQueueProvider)
        .enqueue(id: img.id, localPath: img.localPath);
  }

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

  void updateTitle(String v) => apply(_F.title(state, v));
  void updateDescription(String v) => apply(_F.description(state, v));
  void updateCategoryL1(String? id) => apply(_F.categoryL1(state, id));
  void updateCategoryL2(String? id) => apply(_F.categoryL2(state, id));
  void updateCondition(ListingCondition? c) => apply(_F.condition(state, c));
  void updatePrice(int cents) => apply(_F.price(state, cents));
  void updateShipping(ShippingCarrier c, WeightRange? r) =>
      apply(_F.shipping(state, c, r));
  void updateLocation(String? pc) => apply(_F.location(state, pc));

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
      _draftTimer?.cancel();
      await ref.read(draftPersistenceServiceProvider).clear();
    } on Object catch (_) {
      state = state.copyWith(isLoading: false, errorKey: () => errorKey);
    }
  }

  void apply(ListingCreationState next) {
    state = next;
    _draftTimer?.cancel();
    _draftTimer = Timer(
      _draftDebounce,
      () => ref.read(draftPersistenceServiceProvider).save(state),
    );
  }

  void _applyPick(({ListingCreationState state, List<SellImage> newImages}) o) {
    apply(o.state);
    final q = ref.read(photoUploadQueueProvider);
    for (final i in o.newImages) {
      q.enqueue(id: i.id, localPath: i.localPath);
    }
  }

  void _onOutcome(PhotoUploadOutcome outcome) {
    state = PhotoOperations.applyOutcome(state, outcome);
    if (outcome is PhotoUploadSucceeded) apply(state);
  }
}
