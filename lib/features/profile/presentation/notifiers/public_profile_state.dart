import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_aggregate.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_entity.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';

/// Per-section independent AsyncValue state for public profile.
///
/// Mirrors [ProfileState] pattern: error in one section does not
/// block others (Tier-1 audit requirement).
class PublicProfileState {
  const PublicProfileState({
    this.user = const AsyncValue.loading(),
    this.aggregate = const AsyncValue.loading(),
    this.listings = const AsyncValue.loading(),
    this.reviews = const AsyncValue.loading(),
  });

  final AsyncValue<UserEntity?> user;
  final AsyncValue<ReviewAggregate> aggregate;
  final AsyncValue<List<ListingEntity>> listings;
  final AsyncValue<List<ReviewEntity>> reviews;

  PublicProfileState copyWith({
    AsyncValue<UserEntity?>? user,
    AsyncValue<ReviewAggregate>? aggregate,
    AsyncValue<List<ListingEntity>>? listings,
    AsyncValue<List<ReviewEntity>>? reviews,
  }) {
    return PublicProfileState(
      user: user ?? this.user,
      aggregate: aggregate ?? this.aggregate,
      listings: listings ?? this.listings,
      reviews: reviews ?? this.reviews,
    );
  }
}
