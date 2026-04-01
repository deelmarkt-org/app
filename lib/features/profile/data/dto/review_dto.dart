import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';

/// DTO for converting Supabase REST JSON to [ReviewEntity].
///
/// Defensive parsing — validates required fields, uses tryParse for dates.
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
      throw FormatException(
        'ReviewDto.fromJson: missing required fields '
        '(id=$id, reviewer_id=$reviewerId, reviewer_name=$reviewerName, '
        'reviewee_id=$revieweeId, listing_id=$listingId, rating=$rating, text=$text)',
      );
    }

    return ReviewEntity(
      id: id,
      reviewerId: reviewerId,
      reviewerName: reviewerName,
      revieweeId: revieweeId,
      listingId: listingId,
      rating: rating.toDouble(),
      text: text,
      reviewerAvatarUrl: json['reviewer_avatar_url'] as String?,
      createdAt:
          createdAtRaw is String
              ? (DateTime.tryParse(createdAtRaw) ?? DateTime.now())
              : DateTime.now(),
    );
  }

  /// Parse a list of JSON rows. Skips malformed entries.
  static List<ReviewEntity> fromJsonList(List<dynamic> jsonList) {
    return jsonList.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }
}
