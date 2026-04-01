import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/supabase_service.dart';
import 'package:deelmarkt/core/domain/entities/category_entity.dart';
import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/core/domain/entities/user_entity.dart';

class ListingDetailState extends Equatable {
  const ListingDetailState({
    required this.listing,
    this.seller,
    this.category,
    this.isOwnListing = false,
  });

  final ListingEntity listing;
  final UserEntity? seller;
  final CategoryEntity? category;
  final bool isOwnListing;

  ListingDetailState copyWith({
    ListingEntity? listing,
    UserEntity? seller,
    CategoryEntity? category,
    bool? isOwnListing,
  }) {
    return ListingDetailState(
      listing: listing ?? this.listing,
      seller: seller ?? this.seller,
      category: category ?? this.category,
      isOwnListing: isOwnListing ?? this.isOwnListing,
    );
  }

  @override
  List<Object?> get props => [listing, seller, category, isOwnListing];
}

/// Provider family keyed by listing ID.
final listingDetailNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<ListingDetailNotifier, ListingDetailState, String>(
      ListingDetailNotifier.new,
    );

class ListingDetailNotifier
    extends AutoDisposeFamilyAsyncNotifier<ListingDetailState, String> {
  @override
  Future<ListingDetailState> build(String arg) async {
    final listingRepo = ref.watch(listingRepositoryProvider);
    final userRepo = ref.watch(userRepositoryProvider);
    final categoryRepo = ref.watch(categoryRepositoryProvider);

    final listing = await listingRepo.getById(arg);
    if (listing == null) {
      throw Exception('Listing not found');
    }

    // Determine if this is the current user's listing.
    final currentUser = ref.watch(currentUserProvider);
    final isOwnListing =
        currentUser != null && currentUser.id == listing.sellerId;

    // Fetch seller profile and category in parallel.
    UserEntity? seller;
    CategoryEntity? category;
    await Future.wait([
      () async {
        try {
          seller = await userRepo.getById(listing.sellerId);
        } on Exception catch (e) {
          AppLogger.warning(
            'Failed to load seller profile',
            error: e,
            tag: 'listing-detail',
          );
        }
      }(),
      () async {
        try {
          category = await categoryRepo.getById(listing.categoryId);
        } on Exception catch (e) {
          AppLogger.warning(
            'Failed to load category',
            error: e,
            tag: 'listing-detail',
          );
        }
      }(),
    ]);

    return ListingDetailState(
      listing: listing,
      seller: seller,
      category: category,
      isOwnListing: isOwnListing,
    );
  }

  Future<void> toggleFavourite() async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Optimistic UI
    final optimistic = current.listing.copyWith(
      isFavourited: !current.listing.isFavourited,
    );
    state = AsyncValue.data(current.copyWith(listing: optimistic));

    try {
      final repo = ref.read(listingRepositoryProvider);
      final updated = await repo.toggleFavourite(current.listing.id);
      state = AsyncValue.data(current.copyWith(listing: updated));
    } on Exception catch (e) {
      AppLogger.error(
        'Failed to toggle favourite',
        error: e,
        tag: 'listing-detail',
      );
      state = AsyncValue.data(current);
    }
  }
}
