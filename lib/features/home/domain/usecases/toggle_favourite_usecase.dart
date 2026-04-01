import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/domain/repositories/listing_repository.dart';

/// Toggles the favourite status of a listing.
class ToggleFavouriteUseCase {
  const ToggleFavouriteUseCase(this._repo);

  final ListingRepository _repo;

  /// Toggles favourite and returns the updated listing.
  Future<ListingEntity> call(String listingId) =>
      _repo.toggleFavourite(listingId);
}
