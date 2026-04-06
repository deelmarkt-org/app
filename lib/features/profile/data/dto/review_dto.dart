import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';

/// DTO for converting Supabase REST JSON to [ReviewEntity].
///
/// Defensive parsing — validates required fields, uses tryParse for dates.
/// P-38: extended to parse [transactionId], [role], [isHidden],
/// [isReviewerDeleted], and [updatedAt].
class ReviewDto {
  const ReviewDto._();

  /// Parse a Supabase JSON row from `reviews` table.
  static ReviewEntity fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final reviewerId = json['reviewer_id'];
    final reviewerName = json['reviewer_name'];
    final revieweeId = json['reviewee_id'];
    final listingId = json['listing_id'];
    final rating = json['rating'];
    final text = json['text'];
    final createdAtRaw = json['created_at'];

    if (id is! String ||
        reviewerId is! String ||
        reviewerName is! String ||
        revieweeId is! String ||
        listingId is! String ||
        rating is! num ||
        text is! String) {
      throw const FormatException(
        'ReviewDto.fromJson: missing or malformed required fields',
      );
    }

    final roleRaw = json['role'] as String?;
    final role = roleRaw == 'seller' ? ReviewRole.seller : ReviewRole.buyer;

    final updatedAtRaw = json['updated_at'] as String?;

    return ReviewEntity(
      id: id,
      transactionId: json['transaction_id'] as String?,
      reviewerId: reviewerId,
      reviewerName: reviewerName,
      revieweeId: revieweeId,
      listingId: listingId,
      role: role,
      rating: rating.toDouble(),
      text: text,
      isHidden: json['is_hidden'] as bool? ?? false,
      isReviewerDeleted: json['is_reviewer_deleted'] as bool? ?? false,
      reviewerAvatarUrl: json['reviewer_avatar_url'] as String?,
      createdAt:
          createdAtRaw is String
              ? (DateTime.tryParse(createdAtRaw) ?? DateTime.now())
              : DateTime.now(),
      updatedAt: updatedAtRaw != null ? DateTime.tryParse(updatedAtRaw) : null,
    );
  }

  /// Parse a list of JSON rows. Skips malformed entries silently.
  static List<ReviewEntity> fromJsonList(List<dynamic> jsonList) {
    final results = <ReviewEntity>[];
    for (final item in jsonList) {
      if (item is! Map<String, dynamic>) continue;
      try {
        results.add(fromJson(item));
      } on FormatException {
        // Skip malformed entries — logged at debug level upstream
      }
    }
    return results;
  }
}
