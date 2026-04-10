import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/domain/repositories/listing_repository.dart';

/// Fetches the current user's own listings for the seller dashboard.
///
/// Wraps [ListingRepository.getByUserId] with a default limit.
class GetSellerListingsUseCase {
  const GetSellerListingsUseCase(this._repo);

  final ListingRepository _repo;

  Future<List<ListingEntity>> call(String userId, {int limit = 20}) =>
      _repo.getByUserId(userId, limit: limit);
}
