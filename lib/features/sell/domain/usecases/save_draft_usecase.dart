import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state_upload.dart';
import 'package:deelmarkt/features/sell/domain/repositories/listing_creation_repository.dart';

/// Saves the current listing creation state as a draft.
///
/// Delegates to [ListingCreationRepository.saveDraft] with lenient
/// parameter requirements — most fields are optional for drafts.
class SaveDraftUseCase {
  const SaveDraftUseCase(this._repository);

  final ListingCreationRepository _repository;

  Future<ListingEntity> call({required ListingCreationState state}) {
    return _repository.saveDraft(
      title: state.title,
      description: state.description,
      priceInCents: state.priceInCents,
      condition: state.condition,
      categoryId: state.categoryL2Id,
      imageUrls: state.uploadedDeliveryUrls,
      location: state.location,
      shippingCarrier: state.shippingCarrier,
      weightRange: state.weightRange,
    );
  }
}
