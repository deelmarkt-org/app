import 'package:equatable/equatable.dart';

/// Review left by a buyer for a seller after a transaction.
///
/// Immutable value object — domain layer, no Flutter/Supabase imports.
/// Extends [Equatable] for Riverpod state diffing (ADR-21).
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
    this.reviewerAvatarUrl,
  });

  final String id;
  final String reviewerId;
  final String reviewerName;
  final String revieweeId;
  final String listingId;
  final double rating;
  final String text;
  final DateTime createdAt;
  final String? reviewerAvatarUrl;

  @override
  List<Object?> get props => [
    id,
    reviewerId,
    reviewerName,
    revieweeId,
    listingId,
    rating,
    text,
    createdAt,
    reviewerAvatarUrl,
  ];
}
