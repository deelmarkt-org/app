import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';

/// Review repository interface — domain layer.
///
/// Implementations: MockReviewRepository (Phase 6), SupabaseReviewRepository (future).
/// Swapped via Riverpod provider overrides — no conditional logic.
abstract class ReviewRepository {
  /// Get reviews for a specific user, paginated by cursor.
  Future<List<ReviewEntity>> getByUserId(
    String userId, {
    int limit = 5,
    String? cursor,
  });
}
