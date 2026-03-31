import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/domain/repositories/listing_repository.dart';

/// Fetches recently added listings for the home screen.
class GetRecentListingsUseCase {
  const GetRecentListingsUseCase(this._repo);

  final ListingRepository _repo;

  /// Returns the most recent listings.
  Future<List<ListingEntity>> call({int limit = 10}) =>
      _repo.getRecent(limit: limit);
}
