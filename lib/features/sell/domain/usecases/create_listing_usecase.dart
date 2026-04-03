import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/repositories/listing_creation_repository.dart';

/// Publishes a new listing from the completed creation state.
///
/// Delegates to [ListingCreationRepository.create] after extracting
/// the required fields from [ListingCreationState].
class CreateListingUseCase {
  const CreateListingUseCase(this._repository);

  final ListingCreationRepository _repository;

  Future<ListingEntity> call({required ListingCreationState state}) {
    final condition = state.condition;
    final categoryId = state.categoryL2Id;
    if (condition == null || categoryId == null) {
      throw ArgumentError('Condition and category are required to publish');
    }

    return _repository.create(
      title: state.title,
      description: state.description,
      priceInCents: state.priceInCents,
      condition: condition,
      categoryId: categoryId,
      imagePaths: state.imageFiles,
      location: state.location,
      shippingCarrier: state.shippingCarrier,
      weightRange: state.weightRange,
    );
  }
}
