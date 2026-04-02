import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/domain/repositories/listing_repository.dart';

/// Retrieves listings created by a specific user.
class GetUserListingsUseCase {
  const GetUserListingsUseCase(this._repository);
  final ListingRepository _repository;

  Future<List<ListingEntity>> call(
    String userId, {
    int limit = 10,
    String? cursor,
  }) {
    return _repository.getByUserId(userId, limit: limit, cursor: cursor);
  }
}
