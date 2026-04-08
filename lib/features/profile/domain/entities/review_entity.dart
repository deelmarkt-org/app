import 'package:equatable/equatable.dart';

import 'package:deelmarkt/features/profile/domain/entities/review_role.dart';
export 'package:deelmarkt/features/profile/domain/entities/review_role.dart';

/// Review left by a buyer or seller after a transaction.
///
/// Immutable value object — domain layer, no Flutter/Supabase imports.
/// Extends [Equatable] for Riverpod state diffing (ADR-21).
///
/// P-38: extended with [transactionId], [role], [isHidden], [isReviewerDeleted],
/// and [updatedAt] for blind review flow (E06 lines 24–29).
class ReviewEntity extends Equatable {
  const ReviewEntity({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    required this.revieweeId,
    required this.listingId,
    required this.rating,
    required this.text,
    required this.createdAt,
    this.transactionId,
    this.reviewerAvatarUrl,
    this.role = ReviewRole.buyer,
    this.isHidden = false,
    this.isReviewerDeleted = false,
    this.updatedAt,
  });

  final String id;

  /// Transaction this review belongs to. Null for legacy reviews.
  final String? transactionId;

  final String reviewerId;
  final String reviewerName;
  final String? reviewerAvatarUrl;
  final String revieweeId;
  final String listingId;

  /// Whether reviewer acted as buyer or seller in the transaction.
  final ReviewRole role;

  final double rating;
  final String text;

  /// Server-authoritative visibility flag for blind review flow.
  /// When true, the review is hidden from the counterparty until both submit.
  /// See ADR-BLIND-REVIEW-AUTHORITY.
  final bool isHidden;

  /// GDPR Art. 17 tombstone — reviewer account has been deleted.
  /// When true, display "Verwijderde gebruiker" and generic avatar.
  final bool isReviewerDeleted;

  final DateTime createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
    id,
    transactionId,
    reviewerId,
    reviewerName,
    reviewerAvatarUrl,
    revieweeId,
    listingId,
    role,
    rating,
    text,
    isHidden,
    isReviewerDeleted,
    createdAt,
    updatedAt,
  ];

  ReviewEntity copyWith({
    String? id,
    String? transactionId,
    String? reviewerId,
    String? reviewerName,
    String? reviewerAvatarUrl,
    String? revieweeId,
    String? listingId,
    ReviewRole? role,
    double? rating,
    String? text,
    bool? isHidden,
    bool? isReviewerDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewEntity(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewerAvatarUrl: reviewerAvatarUrl ?? this.reviewerAvatarUrl,
      revieweeId: revieweeId ?? this.revieweeId,
      listingId: listingId ?? this.listingId,
      role: role ?? this.role,
      rating: rating ?? this.rating,
      text: text ?? this.text,
      isHidden: isHidden ?? this.isHidden,
      isReviewerDeleted: isReviewerDeleted ?? this.isReviewerDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
