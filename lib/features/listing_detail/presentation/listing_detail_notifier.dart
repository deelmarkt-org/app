import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/core/services/performance/performance_tracer_provider.dart';
import 'package:deelmarkt/core/services/performance/trace_names.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/domain/entities/category_entity.dart';
import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/core/domain/entities/user_entity.dart';
import 'package:deelmarkt/core/domain/repositories/category_repository.dart';
import 'package:deelmarkt/core/domain/repositories/user_repository.dart';

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
  static const _logTag = 'listing-detail';

  @override
  Future<ListingDetailState> build(String arg) async {
    // Hoist all ref.watch calls before any await — Riverpod's subscription
    // lifecycle is only guaranteed when watch() runs synchronously inside
    // build(). Reading after an async gap risks lost rebuild invalidations.
    final listingRepo = ref.watch(listingRepositoryProvider);
    final userRepo = ref.watch(userRepositoryProvider);
    final categoryRepo = ref.watch(categoryRepositoryProvider);
    final currentUser = ref.watch(currentUserProvider);

    // GH #221 listing_load trace; finally closes on any throw too.
    final handle = ref
        .read(performanceTracerProvider)
        .start(TraceNames.listingLoad);
    try {
      final listing = await listingRepo.getById(arg);
      if (listing == null) throw Exception('Listing not found');
      final (seller, category) = await _loadSellerAndCategory(
        listing,
        userRepo: userRepo,
        categoryRepo: categoryRepo,
      );
      return ListingDetailState(
        listing: listing,
        seller: seller,
        category: category,
        isOwnListing: currentUser?.id == listing.sellerId,
      );
    } finally {
      await handle.stop();
    }
  }

  /// Parallel fetch of seller + category. Errors are logged but don't
  /// propagate so the listing still renders if a sub-fetch fails.
  /// Repositories are passed in from `build()` to keep all `ref.watch`
  /// subscriptions synchronous (Riverpod best practice).
  Future<(UserEntity?, CategoryEntity?)> _loadSellerAndCategory(
    ListingEntity listing, {
    required UserRepository userRepo,
    required CategoryRepository categoryRepo,
  }) async {
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
            tag: _logTag,
          );
        }
      }(),
      () async {
        try {
          category = await categoryRepo.getById(listing.categoryId);
        } on Exception catch (e) {
          AppLogger.warning('Failed to load category', error: e, tag: _logTag);
        }
      }(),
    ]);
    return (seller, category);
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
      AppLogger.error('Failed to toggle favourite', error: e, tag: _logTag);
      state = AsyncValue.data(current);
    }
  }
}
