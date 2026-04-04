import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/domain/repositories/listing_repository.dart';

/// Fetches the current user's favourited listings.
class GetFavouritesUseCase {
  const GetFavouritesUseCase(this._repo);

  final ListingRepository _repo;

  /// Returns all listings the user has favourited.
  Future<List<ListingEntity>> call() => _repo.getFavourites();
}
