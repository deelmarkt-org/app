import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';
import 'package:deelmarkt/features/profile/domain/repositories/review_repository.dart';

/// Retrieves reviews for a specific user.
class GetUserReviewsUseCase {
  const GetUserReviewsUseCase(this._repository);
  final ReviewRepository _repository;

  Future<List<ReviewEntity>> call(
    String userId, {
    int limit = 5,
    String? cursor,
  }) {
    return _repository.getByUserId(userId, limit: limit, cursor: cursor);
  }
}
